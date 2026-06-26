# Daily Log — AWS Containerized Full Stack App

A private daily journal application built on AWS, demonstrating containerized workloads, relational databases, authentication, and infrastructure as code.

> **Live demo:** [CONTACT ME FOR LIVE DEMO]  
> **Portfolio:** [aleksandermatusik.xyz](https://aleksandermatusik.xyz)

**Update 26.06.2026** I can boot up whole app using terraform, only adding dns manually to namecheap as a project3.aleksandermatusik.xyz

---

## Architecture

```mermaid
flowchart TD
    User(["User"])

    subgraph Frontend["Frontend"]
        CF["CloudFront"]
        S3["S3\nindex.html"]
    end

    subgraph Auth["Authentication"]
        CUP["Cognito\nUser Pool"]
        HUI["Cognito\nHosted UI"]
    end

    subgraph API["API Layer"]
        APIGW["API Gateway\nHTTP API\n+ JWT Authorizer"]
    end

    subgraph Network["VPC — eu-west-1"]
        ALB["Application\nLoad Balancer\npublic subnets"]

        subgraph Private["Private Subnets"]
            ECS["ECS Fargate\nFlask API\n:5000"]
            RDS[("RDS Postgres\ndailylog db")]
        end
    end

    subgraph Storage["Supporting Services"]
        SM["Secrets Manager\nDB credentials"]
        ECR["ECR\nDocker image"]
        CW["CloudWatch\nLogs"]
    end

    subgraph CICD["CI/CD — GitHub Actions"]
        TF["terraform.yml\ninfrastructure"]
        DP["deploy.yml\nbuild → ECR → ECS"]
    end

    User -->|"visits site"| CF
    CF -->|"serves"| S3
    User -->|"clicks Sign In"| HUI
    HUI -->|"managed by"| CUP
    CUP -->|"returns JWT token"| User
    User -->|"API calls + JWT"| APIGW
    APIGW -->|"validates token"| CUP
    APIGW -->|"forwards request"| ALB
    ALB -->|"routes traffic"| ECS
    ECS -->|"reads credentials"| SM
    ECS -->|"queries"| RDS
    ECS -->|"sends logs"| CW
    ECR -->|"image pulled by"| ECS
    DP -->|"pushes image"| ECR
    DP -->|"redeploys"| ECS
    TF -->|"provisions"| Network
    TF -->|"provisions"| Auth
    TF -->|"provisions"| API
    TF -->|"provisions"| Frontend
```

---

## AWS Services Used

| Service | Purpose |
|---|---|
| **ECS Fargate** | Runs containerized Flask API — no EC2 to manage |
| **ECR** | Private Docker image registry |
| **RDS PostgreSQL** | Relational database for journal entries |
| **Cognito** | User authentication and JWT token issuance |
| **API Gateway** | HTTP API with JWT authorizer — validates every request |
| **ALB** | Routes traffic from API Gateway to ECS tasks |
| **CloudFront** | CDN serving the static frontend globally |
| **S3** | Hosts the static HTML/JS frontend |
| **Secrets Manager** | Stores RDS credentials — never hardcoded |
| **VPC** | Isolated network with public and private subnets |
| **NAT Gateway** | Allows private subnet outbound internet access |
| **CloudWatch** | Container log aggregation |
| **IAM** | Least privilege roles for ECS task execution |
| **ACM** | SSL/TLS certificates for HTTPS |

---

## Key Design Decisions (incomplete)

**Private subnets for compute and data**
ECS tasks and RDS both run in private subnets with no public internet exposure. Only the ALB and NAT Gateway sit in public subnets. Traffic flows inward through API Gateway → ALB → ECS → RDS.

**Secrets Manager over environment variables**
Database credentials are never stored in code, task definitions, or environment variables. The Flask API fetches credentials from Secrets Manager at runtime using the ECS task IAM role.

**API Gateway as the security boundary**
Every request hits API Gateway first. The Cognito JWT authorizer validates tokens before any request reaches the ALB or ECS. Unauthenticated requests are rejected at the edge.

**RDS snapshots for cost-optimised persistence**
The stack is torn down when not in use to avoid ongoing RDS costs. A final snapshot is taken automatically on `terraform destroy` and restored on the next `terraform apply` — data persists across teardowns at near-zero cost. (The snapshot recreation will be edited manually in variables.tf by the restore_snapshot_id.) 

**Path-filtered CI/CD pipelines**
Two separate GitHub Actions workflows with path filters ensure infrastructure and application deployments are fully independent. Changing app code never triggers a Terraform run and vice versa.

---

## API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/health` | Health check — no auth required |
| `GET` | `/entries` | Get all entries for the authenticated user |
| `POST` | `/entries` | Create a new entry |
| `DELETE` | `/entries/:id` | Delete an entry |

---

## Problems I encountered
1. The api configuration and deployment is the first circle of hell they say, my calls to /health were giving the same response, alb url gave "only traffic from api" and my api made the same error. Flask was recieving requests but somehow i still couldn't check my app. Somehow my api gateway routes wasn't working, I decided to get rid of jwt token from apigateway and let the flask handle everything.
2. When testing deployment I had to manually get my outputs.tf and paste them into index.html. I wanted full automation so I implemented a technique where terraform takes variables from root output.tf and pastes it into now, better, faster - index.html.tpl. I also changed the wrong output I was getting from cognito/outputs.tf insted of user_pool_clients_id i was using user_pool_id.
3. Whole lot of wrong IAM permissions added so ecs could not pull porperly from ecr changed permissions to * will change it later.
4. Tired of creating fresh rds table after every terraform apply, especially if I had to make a bastion I could connect to the rds, tired of all security groups creation, etc. made a slight ajustment in app.py so it creates table for me. In the meantime I placed the call function incorrectly, had to change it after couple of failed deployments. 
5. While tearing down app the snapshot rds name was the same, made a 4byte hex that will generate random string attached to snapshot name. When backing up database from snapshot, I will have to manually point it to the latest one in my console.
---

## Infrastructure — Deploy and Destroy

**First deploy:**
```bash
cd terraform
terraform init
terraform apply
```

**Deploy new app version** (handled automatically by CI/CD on push to `/app`):
```bash
git push origin main
```

**Tear down** (snapshot taken automatically before destroy):
```bash
terraform destroy
```

**Restore from snapshot** — update `terraform.tfvars`:
```hcl
snapshot_identifier = "dailylog-final-snapshot"
```
Then run `terraform apply` — RDS restores from snapshot, all data intact.

---

## Local Development

```bash
cd app
pip install -r requirements.txt

# Run locally (health endpoint only — RDS is in private subnet)
flask run --port 5000

# Or with Docker
docker build -t dailylog-api .
docker run -p 5000:5000 -e DB_HOST=placeholder -e DB_NAME=dailylog dailylog-api

curl http://localhost:5000/health
# {"status": "healthy"}
```

---

## CI/CD Pipeline

**terraform.yml** — triggers on changes to `/terraform/**`
```
Push → terraform fmt → terraform validate → terraform plan → terraform apply
```

**deploy.yml** — triggers on changes to `/app/**`
```
Push → docker build → push to ECR → ecs update-service (rolling deploy)
```

Both pipelines authenticate to AWS using **OIDC** — no long-lived AWS credentials stored in GitHub secrets.

---