# Dental Receptionist AI - Deployment Guide

This guide will help you deploy your Nova Sonic-based Dental Receptionist AI to AWS.

## 📋 Prerequisites

Before deploying, ensure you have:

1. **AWS Account** with:
   - AWS Bedrock access enabled (specifically for Nova Sonic model)
   - Sufficient permissions to create ECS, ECR, VPC, ALB resources
   - AWS CLI installed and configured

2. **Development Tools**:
   - Docker installed
   - Node.js 18+ (for local testing)
   - Git

3. **Repository**:
   - Fork or clone the `aws-samples/sample-nova-sonic-mcp` repository

## 🚀 Quick Deployment (Recommended Path)

### Step 1: Request Bedrock Model Access

```bash
# 1. Go to AWS Console → Amazon Bedrock → Model access
# 2. Request access to "Amazon Nova Sonic" model
# 3. Wait for approval (usually instant for AWS accounts)

# Verify access via CLI:
aws bedrock list-foundation-models --region us-east-1 \
  --query 'modelSummaries[?contains(modelId, `nova-sonic`)]'
```

### Step 2: Clone and Setup

```bash
# Clone the repository
git clone https://github.com/aws-samples/sample-nova-sonic-mcp.git
cd sample-nova-sonic-mcp

# Install dependencies
npm install

# Copy the dental receptionist files
cp /path/to/dental-receptionist-config.js .
cp /path/to/dental-receptionist-ui.html public/index.html
cp /path/to/Dockerfile .
cp /path/to/cloudformation-template.yaml deploy/
```

### Step 3: Update Server Code

Edit your `server.ts` (or create a new one) to include the dental receptionist configuration:

```typescript
// At the top of server.ts
const { DENTAL_RECEPTIONIST_PROMPT } = require('./dental-receptionist-config.js');

// In your socket connection handler
socket.on('connection', (client) => {
  // Send the dental receptionist prompt as the system prompt
  client.emit('systemPrompt', DENTAL_RECEPTIONIST_PROMPT);
  
  // Set default voice
  client.emit('voiceConfig', { voiceId: 'tiffany' });
});
```

### Step 4: Test Locally

```bash
# Build the application
npm run build

# Start the server
npm start

# Open browser to http://localhost:3000
# Test the receptionist by speaking to it
```

### Step 5: Build and Push Docker Image

```bash
# Set your AWS account ID and region
export AWS_ACCOUNT_ID="your-account-id"
export AWS_REGION="us-east-1"
export IMAGE_NAME="dental-receptionist"

# Create ECR repository
aws ecr create-repository \
  --repository-name ${IMAGE_NAME} \
  --region ${AWS_REGION}

# Login to ECR
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin \
  ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Build Docker image
docker build -t ${IMAGE_NAME}:latest .

# Tag for ECR
docker tag ${IMAGE_NAME}:latest \
  ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE_NAME}:latest

# Push to ECR
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE_NAME}:latest
```

### Step 6: Deploy with CloudFormation

```bash
# Deploy the CloudFormation stack
aws cloudformation create-stack \
  --stack-name dental-receptionist \
  --template-body file://deploy/cloudformation-template.yaml \
  --parameters \
    ParameterKey=ContainerImage,ParameterValue=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE_NAME}:latest \
    ParameterKey=DesiredCount,ParameterValue=1 \
  --capabilities CAPABILITY_IAM \
  --region ${AWS_REGION}

# Wait for stack creation (takes 5-10 minutes)
aws cloudformation wait stack-create-complete \
  --stack-name dental-receptionist \
  --region ${AWS_REGION}

# Get the Load Balancer URL
aws cloudformation describe-stacks \
  --stack-name dental-receptionist \
  --region ${AWS_REGION} \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
  --output text
```

### Step 7: Configure Custom Domain (Optional)

If you want to use a custom domain like `receptionist.yourdentalpractice.com`:

```bash
# 1. Request an ACM certificate
aws acm request-certificate \
  --domain-name receptionist.yourdentalpractice.com \
  --validation-method DNS \
  --region ${AWS_REGION}

# 2. Follow the DNS validation steps in ACM console

# 3. Update your CloudFormation stack with certificate ARN
aws cloudformation update-stack \
  --stack-name dental-receptionist \
  --template-body file://deploy/cloudformation-template.yaml \
  --parameters \
    ParameterKey=ContainerImage,ParameterValue=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE_NAME}:latest \
    ParameterKey=CertificateArn,ParameterValue=arn:aws:acm:region:account:certificate/xxx \
  --capabilities CAPABILITY_IAM

# 4. Create Route53 record pointing to ALB
```

## 🔧 Configuration

### Customizing the Receptionist

Edit `dental-receptionist-config.js` to:

1. **Update Practice Information**:
```javascript
// Change location, hours, phone number, etc.
- Location: City centre, near the main market area
+ Location: Your actual address
```

2. **Modify Services**:
```javascript
// Add or remove dental services
// Update pricing
// Change appointment policies
```

3. **Adjust Response Style**:
```javascript
// Make it more formal/casual
// Add practice-specific phrases
// Include staff names
```

### Customizing the UI

Edit `public/index.html` to:

1. **Add Your Logo**:
```html
<div class="practice-logo">
  <img src="./your-logo.png" alt="Practice Logo">
  <h1>Your Practice Name</h1>
</div>
```

2. **Update Colors**:
```css
:root {
  --primary-color: #yourcolor;
  --secondary-color: #yourcolor;
}
```

3. **Change Contact Info**:
```html
<div class="practice-info">
  <span>Your Phone Number</span>
  <span>Your Address</span>
  <span>Your Hours</span>
</div>
```

## 📊 Monitoring and Logs

### View Application Logs

```bash
# Stream logs from CloudWatch
aws logs tail /ecs/dental-receptionist \
  --follow \
  --region ${AWS_REGION}
```

### Monitor Performance

```bash
# Check ECS service status
aws ecs describe-services \
  --cluster dental-receptionist-cluster \
  --services dental-receptionist-service \
  --region ${AWS_REGION}

# View CloudWatch metrics in AWS Console
# Navigate to: CloudWatch → Dashboards
```

### Set Up Alarms

```bash
# Create CPU alarm
aws cloudwatch put-metric-alarm \
  --alarm-name dental-receptionist-high-cpu \
  --alarm-description "Alert when CPU exceeds 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2
```

## 🔒 Security Best Practices

### 1. Enable HTTPS
- Use ACM certificate (as shown above)
- Redirect HTTP to HTTPS

### 2. Restrict Access (Optional)
If you want to limit access to specific IPs:

```bash
# Update ALB security group
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxx \
  --protocol tcp \
  --port 443 \
  --cidr your-office-ip/32
```

### 3. Enable WAF (Web Application Firewall)

```bash
# Create WAF WebACL
aws wafv2 create-web-acl \
  --name dental-receptionist-waf \
  --scope REGIONAL \
  --default-action Allow={} \
  --region ${AWS_REGION}

# Associate with ALB
```

### 4. Rotate Credentials
- Use AWS Secrets Manager for sensitive data
- Rotate IAM access keys regularly

## 💰 Cost Optimization

### Expected Monthly Costs (US-East-1)

| Service | Usage | Cost |
|---------|-------|------|
| ECS Fargate | 1 task, 0.5 vCPU, 1GB RAM | ~$15 |
| ALB | Standard | ~$23 |
| Bedrock (Nova Sonic) | ~1000 conversations/month | ~$50-100 |
| Data Transfer | 100GB | ~$9 |
| CloudWatch Logs | 10GB | ~$5 |
| **Total** | | **~$102-127/month** |

### Cost Saving Tips

1. **Use Spot Instances** (for non-production):
```yaml
LaunchType: FARGATE_SPOT  # Save up to 70%
```

2. **Enable Auto-scaling**:
- Scale down during off-hours
- Already configured in CloudFormation template

3. **Optimize Logs**:
```bash
# Reduce log retention
aws logs put-retention-policy \
  --log-group-name /ecs/dental-receptionist \
  --retention-in-days 3
```

4. **Use Reserved Capacity** (for production):
- Save up to 50% with Savings Plans

## 🔄 Updates and Maintenance

### Deploy New Version

```bash
# Build new image
docker build -t ${IMAGE_NAME}:v2 .

# Tag and push
docker tag ${IMAGE_NAME}:v2 \
  ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE_NAME}:v2
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE_NAME}:v2

# Update ECS service with new image
aws ecs update-service \
  --cluster dental-receptionist-cluster \
  --service dental-receptionist-service \
  --force-new-deployment \
  --region ${AWS_REGION}
```

### Rollback

```bash
# List previous task definitions
aws ecs list-task-definitions \
  --family-prefix dental-receptionist

# Update service to previous version
aws ecs update-service \
  --cluster dental-receptionist-cluster \
  --service dental-receptionist-service \
  --task-definition dental-receptionist:1 \
  --region ${AWS_REGION}
```

## 🧪 Testing

### Load Testing

```bash
# Install Apache Bench
sudo apt-get install apache2-utils

# Run load test
ab -n 100 -c 10 http://your-alb-url/
```

### Integration Testing

Create `test-conversation.js`:
```javascript
const io = require('socket.io-client');

const socket = io('http://your-alb-url');

socket.on('connect', () => {
  console.log('Connected to receptionist');
  // Send test audio or commands
});
```

## 🐛 Troubleshooting

### Common Issues

#### 1. "Bedrock Access Denied"
```bash
# Verify Bedrock permissions
aws bedrock list-foundation-models --region us-east-1

# Check IAM role has bedrock:InvokeModel permission
```

#### 2. "Container fails health checks"
```bash
# Check container logs
aws logs tail /ecs/dental-receptionist --follow

# Verify health check endpoint
curl http://container-ip:3000/health
```

#### 3. "WebSocket connection fails"
- Ensure ALB has WebSocket support (enabled by default)
- Check security group rules allow traffic
- Verify SSL certificate if using HTTPS

#### 4. "High latency in responses"
- Check ECS task CPU/memory usage
- Consider increasing task size
- Enable CloudFront for caching static assets

## 📞 Support and Next Steps

### Additional Integrations

1. **Calendar Integration**: Connect to Google Calendar or Outlook
2. **CRM Integration**: Sync patient data with your practice management software
3. **SMS Notifications**: Add Twilio for appointment reminders
4. **Analytics**: Track conversation metrics

### Enhancement Ideas

1. **Multi-language Support**: Add support for other languages
2. **Voice Biometrics**: Identify returning patients by voice
3. **Appointment Booking**: Direct integration with scheduling system
4. **Emergency Escalation**: Auto-transfer to on-call staff for emergencies

## 📚 Additional Resources

- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [Nova Sonic Model Card](https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html)

---

**Need Help?** Open an issue in the repository or contact AWS Support.
