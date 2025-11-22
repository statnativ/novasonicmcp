# AWS Deployment Guide - Dental Receptionist AI

This guide provides step-by-step instructions to deploy your dental receptionist application to AWS.

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- Node.js 18+ installed
- Git installed

## Deployment Options

### Option 1: AWS EC2 (Recommended for Production)

#### Step 1: Launch EC2 Instance

1. **Login to AWS Console**
   - Go to https://console.aws.amazon.com
   - Navigate to EC2 service

2. **Launch Instance**
   - Click "Launch Instance"
   - Name: `dental-receptionist-app`
   - AMI: Ubuntu Server 22.04 LTS
   - Instance type: `t3.medium` (2 vCPU, 4GB RAM minimum)
   - Key pair: Create new or select existing
   - Network settings:
     - Allow SSH (port 22) from your IP
     - Allow HTTP (port 80) from anywhere
     - Allow HTTPS (port 443) from anywhere
     - Allow Custom TCP (port 3000) from anywhere
   - Storage: 20 GB gp3
   - Click "Launch Instance"

#### Step 2: Connect to EC2 Instance

```bash
# SSH into your instance
ssh -i your-key.pem ubuntu@your-ec2-public-ip
```

#### Step 3: Install Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install Git
sudo apt install -y git

# Install PM2 (process manager)
sudo npm install -g pm2

# Verify installations
node --version
npm --version
git --version
```

#### Step 4: Configure AWS Credentials

```bash
# Install AWS CLI
sudo apt install -y awscli

# Configure AWS credentials
aws configure
# Enter your:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region (e.g., us-east-1)
# - Default output format (json)
```

#### Step 5: Clone and Setup Application

```bash
# Clone your repository
cd /home/ubuntu
git clone <your-repository-url>
cd sample-nova-sonic-mcp

# Install dependencies
npm install

# Build the application
npm run build
```

#### Step 6: Configure Environment

```bash
# Create .env file
nano .env
```

Add the following:
```
AWS_REGION=us-east-1
AWS_PROFILE=default
PORT=3000
NODE_ENV=production
```

#### Step 7: Start Application with PM2

```bash
# Start the application
pm2 start npm --name "dental-receptionist" -- start

# Save PM2 configuration
pm2 save

# Setup PM2 to start on system boot
pm2 startup
# Follow the command it outputs

# Check status
pm2 status
pm2 logs dental-receptionist
```

#### Step 8: Setup Nginx Reverse Proxy (Optional but Recommended)

```bash
# Install Nginx
sudo apt install -y nginx

# Create Nginx configuration
sudo nano /etc/nginx/sites-available/dental-receptionist
```

Add this configuration:
```nginx
server {
    listen 80;
    server_name your-domain.com;  # Replace with your domain or EC2 public IP

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

```bash
# Enable the site
sudo ln -s /etc/nginx/sites-available/dental-receptionist /etc/nginx/sites-enabled/

# Test Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

#### Step 9: Setup SSL with Let's Encrypt (Optional)

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal is configured automatically
```

#### Step 10: Configure Security Group

In AWS Console:
1. Go to EC2 → Security Groups
2. Select your instance's security group
3. Edit inbound rules:
   - SSH (22): Your IP only
   - HTTP (80): 0.0.0.0/0
   - HTTPS (443): 0.0.0.0/0
   - Remove port 3000 if using Nginx

---

### Option 2: AWS Elastic Beanstalk (Easier Deployment)

#### Step 1: Install EB CLI

```bash
pip install awsebcli --upgrade --user
```

#### Step 2: Initialize Elastic Beanstalk

```bash
cd sample-nova-sonic-mcp

# Initialize EB
eb init

# Select:
# - Region: us-east-1 (or your preferred region)
# - Application name: dental-receptionist
# - Platform: Node.js
# - Platform version: Node.js 18
# - SSH: Yes (select your key pair)
```

#### Step 3: Create Environment

```bash
# Create environment
eb create dental-receptionist-env

# This will:
# - Create load balancer
# - Launch EC2 instances
# - Configure auto-scaling
# - Deploy your application
```

#### Step 4: Configure Environment Variables

```bash
# Set environment variables
eb setenv AWS_REGION=us-east-1 NODE_ENV=production
```

#### Step 5: Deploy Updates

```bash
# Deploy changes
eb deploy

# Open application
eb open

# Check status
eb status

# View logs
eb logs
```

---

### Option 3: AWS ECS with Fargate (Containerized)

#### Step 1: Create Dockerfile

Already exists in your project. Verify it's correct:

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
```

#### Step 2: Build and Push to ECR

```bash
# Create ECR repository
aws ecr create-repository --repository-name dental-receptionist

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build Docker image
docker build -t dental-receptionist .

# Tag image
docker tag dental-receptionist:latest <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/dental-receptionist:latest

# Push to ECR
docker push <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/dental-receptionist:latest
```

#### Step 3: Create ECS Cluster

```bash
# Create cluster
aws ecs create-cluster --cluster-name dental-receptionist-cluster
```

#### Step 4: Create Task Definition

Create `task-definition.json`:

```json
{
  "family": "dental-receptionist",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::<account-id>:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "dental-receptionist",
      "image": "<your-account-id>.dkr.ecr.us-east-1.amazonaws.com/dental-receptionist:latest",
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "AWS_REGION",
          "value": "us-east-1"
        },
        {
          "name": "NODE_ENV",
          "value": "production"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/dental-receptionist",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

```bash
# Register task definition
aws ecs register-task-definition --cli-input-json file://task-definition.json
```

#### Step 5: Create Service

```bash
# Create service
aws ecs create-service \
  --cluster dental-receptionist-cluster \
  --service-name dental-receptionist-service \
  --task-definition dental-receptionist \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}"
```

---

## Post-Deployment Configuration

### 1. Enable AWS Bedrock Access

```bash
# Ensure your IAM role/user has these permissions:
# - bedrock:InvokeModel
# - bedrock:InvokeModelWithResponseStream
```

IAM Policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": "arn:aws:bedrock:*:*:model/amazon.nova-sonic-v1:0"
    }
  ]
}
```

### 2. Configure Domain (Optional)

1. Register domain in Route 53
2. Create A record pointing to:
   - EC2: Public IP
   - ELB: Load balancer DNS
   - CloudFront: Distribution domain

### 3. Setup Monitoring

```bash
# Enable CloudWatch logs
pm2 install pm2-logrotate

# Configure log rotation
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7
```

### 4. Backup Strategy

```bash
# Create AMI snapshot (EC2)
aws ec2 create-image \
  --instance-id i-xxxxx \
  --name "dental-receptionist-backup-$(date +%Y%m%d)" \
  --description "Backup of dental receptionist app"
```

---

## Maintenance Commands

### EC2 Deployment

```bash
# View logs
pm2 logs dental-receptionist

# Restart application
pm2 restart dental-receptionist

# Update application
cd /home/ubuntu/sample-nova-sonic-mcp
git pull
npm install
npm run build
pm2 restart dental-receptionist

# Monitor resources
pm2 monit
```

### Elastic Beanstalk

```bash
# Deploy updates
eb deploy

# View logs
eb logs

# SSH into instance
eb ssh

# Restart application
eb restart
```

### ECS Fargate

```bash
# Update service
aws ecs update-service \
  --cluster dental-receptionist-cluster \
  --service dental-receptionist-service \
  --force-new-deployment

# View logs
aws logs tail /ecs/dental-receptionist --follow
```

---

## Troubleshooting

### Application won't start
```bash
# Check logs
pm2 logs dental-receptionist --lines 100

# Check AWS credentials
aws sts get-caller-identity

# Verify Bedrock access
aws bedrock list-foundation-models --region us-east-1
```

### High memory usage
```bash
# Increase instance size or container memory
# Monitor with:
pm2 monit
# or
aws cloudwatch get-metric-statistics
```

### WebSocket connection issues
- Ensure security groups allow WebSocket traffic
- Check Nginx configuration for WebSocket support
- Verify CORS settings in server.ts

---

## Cost Estimation

### EC2 (t3.medium)
- Instance: ~$30/month
- Storage: ~$2/month
- Data transfer: Variable
- **Total: ~$35-50/month**

### Elastic Beanstalk
- Similar to EC2 + Load Balancer
- **Total: ~$50-70/month**

### ECS Fargate
- 0.5 vCPU, 1GB RAM: ~$15/month
- **Total: ~$20-30/month**

### Bedrock Nova Sonic
- Pay per use
- ~$0.024 per 1000 input tokens
- ~$0.096 per 1000 output tokens
- Audio: ~$0.012 per minute

---

## Security Best Practices

1. **Use IAM roles** instead of access keys
2. **Enable CloudTrail** for audit logging
3. **Use VPC** for network isolation
4. **Enable encryption** at rest and in transit
5. **Regular security updates**: `sudo apt update && sudo apt upgrade`
6. **Restrict SSH access** to your IP only
7. **Use AWS Secrets Manager** for sensitive data
8. **Enable AWS WAF** for web application firewall

---

## Support

For issues:
1. Check CloudWatch logs
2. Review application logs: `pm2 logs`
3. Verify AWS credentials and permissions
4. Check security group rules
5. Test Bedrock access independently

---

## Next Steps

1. Setup custom domain
2. Configure SSL certificate
3. Enable CloudWatch monitoring
4. Setup automated backups
5. Configure auto-scaling
6. Implement CI/CD pipeline
