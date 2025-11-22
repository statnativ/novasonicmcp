# 📋 Dental Receptionist AI - Setup Checklist

Use this checklist to track your deployment progress.

## Phase 1: Prerequisites ✓

- [ ] AWS Account created and activated
- [ ] AWS CLI installed (`aws --version`)
- [ ] AWS CLI configured (`aws configure`)
- [ ] Docker installed (`docker --version`)
- [ ] Node.js 18+ installed (`node --version`)
- [ ] Git installed (`git --version`)
- [ ] Text editor ready (VS Code, Sublime, etc.)

## Phase 2: AWS Bedrock Setup ✓

- [ ] Login to AWS Console
- [ ] Navigate to Amazon Bedrock service
- [ ] Go to "Model access" section
- [ ] Request access to "Amazon Nova Sonic"
- [ ] Wait for approval (usually instant)
- [ ] Verify access: `aws bedrock list-foundation-models --region us-east-1`

## Phase 3: Clone and Setup Repository ✓

- [ ] Clone repository: `git clone https://github.com/aws-samples/sample-nova-sonic-mcp.git`
- [ ] Navigate to directory: `cd sample-nova-sonic-mcp`
- [ ] Install dependencies: `npm install`
- [ ] Test that it runs: `npm start`
- [ ] Access at http://localhost:3000
- [ ] Stop the server (Ctrl+C)

## Phase 4: Add Dental Receptionist Files ✓

- [ ] Copy `dental-receptionist-config.js` to project root
- [ ] Copy `dental-receptionist-ui.html` to `public/index.html`
- [ ] Copy `Dockerfile` to project root
- [ ] Copy `cloudformation-template.yaml` to `deploy/` folder
- [ ] Copy `deploy.sh` to project root
- [ ] Make deploy script executable: `chmod +x deploy.sh`

## Phase 5: Customize for Your Practice ✓

### Update Configuration File

Edit `dental-receptionist-config.js`:

- [ ] Practice name: ________________
- [ ] Address: ________________
- [ ] Phone number: ________________
- [ ] Hours of operation: ________________
- [ ] Services offered (add/remove as needed)
- [ ] Pricing (convert to your currency/prices)
- [ ] Appointment policies
- [ ] Emergency procedures

### Update UI

Edit `public/index.html`:

- [ ] Replace practice name in header
- [ ] Add your logo (or replace SVG)
- [ ] Update phone number display
- [ ] Update address display
- [ ] Update hours display
- [ ] Change colors to match your brand:
  - Primary color: ________________
  - Secondary color: ________________

### Update Server Code

Edit your `server.ts`:

- [ ] Import dental receptionist config at top
- [ ] Apply system prompt on connection
- [ ] Set default voice ('tiffany' recommended)
- [ ] Add patient info collection handlers (optional)
- [ ] Add appointment scheduling handlers (optional)

## Phase 6: Test Locally ✓

- [ ] Build: `npm run build`
- [ ] Start: `npm start`
- [ ] Open browser to http://localhost:3000
- [ ] Grant microphone permissions
- [ ] Click call button
- [ ] Test conversation: "Hello, I'd like to schedule an appointment"
- [ ] Verify it responds appropriately
- [ ] Check patient info panel displays
- [ ] Test emergency detection: "I have severe tooth pain"
- [ ] Verify conversation display works
- [ ] Test on mobile device (optional)
- [ ] Stop server (Ctrl+C)

## Phase 7: Prepare for AWS Deployment ✓

- [ ] Set AWS_ACCOUNT_ID: `export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)`
- [ ] Set AWS_REGION: `export AWS_REGION=us-east-1` (or your preferred region)
- [ ] Verify AWS permissions (ECS, ECR, CloudFormation, ALB, IAM)
- [ ] Review costs estimate (see README.md)
- [ ] Decide on environment name: ________________

## Phase 8: Deploy to AWS ✓

### Option A: Automated Deployment (Recommended)

- [ ] Run: `./deploy.sh production`
- [ ] Wait for completion (10-15 minutes)
- [ ] Note the Application URL: ________________
- [ ] Test the deployed application
- [ ] Verify HTTPS works (if certificate configured)

### Option B: Manual Deployment

- [ ] Create ECR repository
- [ ] Build Docker image
- [ ] Push to ECR
- [ ] Deploy CloudFormation stack
- [ ] Wait for stack completion
- [ ] Get ALB URL from stack outputs

## Phase 9: Post-Deployment Configuration ✓

- [ ] Test the live application
- [ ] Verify WebSocket connections work
- [ ] Test voice interactions
- [ ] Verify patient info collection
- [ ] Check CloudWatch logs: `aws logs tail /ecs/dental-receptionist --follow`
- [ ] Set up CloudWatch alarms (optional)
- [ ] Configure custom domain (optional)
  - [ ] Request ACM certificate
  - [ ] Validate certificate
  - [ ] Update CloudFormation with certificate ARN
  - [ ] Create Route53 record
- [ ] Enable WAF (optional)
- [ ] Configure backup/disaster recovery (optional)

## Phase 10: Integration & Enhancement ✓

Optional integrations:

- [ ] Connect to practice management system
  - System name: ________________
  - API endpoint: ________________
  - Authentication method: ________________

- [ ] Add SMS notifications (Twilio)
  - [ ] Create Twilio account
  - [ ] Get phone number
  - [ ] Add Twilio credentials to AWS Secrets Manager
  - [ ] Implement SMS sending in code

- [ ] Add email notifications
  - [ ] Set up SES
  - [ ] Verify domain
  - [ ] Implement email sending

- [ ] Add calendar integration
  - [ ] Choose calendar (Google, Outlook, etc.)
  - [ ] Set up OAuth
  - [ ] Implement calendar sync

- [ ] Add analytics
  - [ ] Set up tracking
  - [ ] Create dashboard
  - [ ] Define KPIs

## Phase 11: Training & Documentation ✓

- [ ] Create internal documentation
- [ ] Train staff on system
- [ ] Create troubleshooting guide
- [ ] Document custom configurations
- [ ] Set up monitoring alerts
- [ ] Define escalation procedures
- [ ] Create backup/restore procedures

## Phase 12: Go Live ✓

- [ ] Final end-to-end test
- [ ] Verify emergency procedures
- [ ] Test with real staff members
- [ ] Update website with receptionist info (optional)
- [ ] Update phone system (optional)
- [ ] Monitor for first week
- [ ] Collect feedback
- [ ] Make adjustments as needed

## Maintenance Schedule

### Daily
- [ ] Check CloudWatch logs for errors
- [ ] Verify service is running
- [ ] Monitor conversation quality

### Weekly
- [ ] Review conversation transcripts
- [ ] Check cost reports
- [ ] Update knowledge base if needed

### Monthly
- [ ] Review analytics
- [ ] Update pricing/policies if changed
- [ ] Check for security updates
- [ ] Review and optimize costs

### Quarterly
- [ ] Full security audit
- [ ] Disaster recovery test
- [ ] Review and update documentation
- [ ] Staff training refresh

## Emergency Contacts

AWS Support: ________________
DevOps Lead: ________________
Practice Manager: ________________
IT Support: ________________

## Important URLs

Application URL: ________________
AWS Console: https://console.aws.amazon.com
CloudWatch Logs: ________________
ECR Repository: ________________

## Notes

_Use this section for any specific notes about your deployment:_

_______________________________________________

_______________________________________________

_______________________________________________

_______________________________________________

---

**Deployment Date:** _______________
**Deployed By:** _______________
**Version:** _______________
**Environment:** _______________
