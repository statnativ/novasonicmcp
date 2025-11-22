# 🦷 Dental Receptionist AI - Nova Sonic Edition

An intelligent, voice-powered dental receptionist built on Amazon Nova Sonic (AWS Bedrock) that handles patient inquiries, schedules appointments, and provides professional dental practice information 24/7.

## ✨ Features

- 🎤 **Real-time Voice Conversations** - Natural speech-to-speech interactions using Amazon Nova Sonic
- 📞 **Professional Reception** - Grounded on comprehensive dental practice knowledge base
- 📅 **Appointment Management** - Collect patient information and schedule appointments
- 🚨 **Emergency Detection** - Automatically identifies and prioritizes dental emergencies
- 🎨 **Customizable UI** - Brand it with your practice logo, colors, and information
- 📊 **Patient Tracking** - Collects and displays caller information in real-time
- 🔒 **HIPAA-Ready Architecture** - Secure AWS infrastructure suitable for healthcare
- 🌐 **WebSocket Streaming** - Low-latency, bidirectional audio communication
- 📱 **Responsive Design** - Works on desktop, tablet, and mobile devices

## 🎯 Use Cases

- **After-hours Reception** - Handle patient calls when your office is closed
- **Call Overflow** - Manage high call volumes during busy periods
- **Initial Triage** - Collect patient information before connecting to staff
- **FAQ Handling** - Answer common questions about services, hours, insurance
- **Emergency Prioritization** - Identify urgent cases that need immediate attention
- **Multilingual Support** - Can be configured for multiple languages

## 📋 What's Included

This repository contains everything you need to deploy a production-ready dental receptionist:

1. **`dental-receptionist-config.js`** - Comprehensive knowledge base with:
   - Practice information (location, hours, services)
   - Treatment details and pricing
   - Common Q&A (80+ questions)
   - Appointment policies
   - Emergency protocols

2. **`dental-receptionist-ui.html`** - Professional web interface with:
   - Branded header with practice info
   - Real-time audio visualization
   - Patient information panel
   - Conversation display
   - Emergency indicators

3. **`server-modifications.ts`** - Backend integration showing:
   - System prompt implementation
   - Patient data collection
   - Appointment scheduling hooks
   - Session management

4. **`Dockerfile`** - Production-ready containerization

5. **`cloudformation-template.yaml`** - Complete AWS infrastructure:
   - ECS Fargate cluster
   - Application Load Balancer
   - Auto-scaling configuration
   - CloudWatch logging
   - Security groups and IAM roles

6. **`deploy.sh`** - Automated deployment script

7. **`DEPLOYMENT-GUIDE.md`** - Comprehensive deployment documentation

## 🚀 Quick Start

### Prerequisites

- AWS Account with Bedrock access
- AWS CLI configured
- Docker installed
- Node.js 18+ installed

### 1. Clone the Repository

```bash
git clone https://github.com/aws-samples/sample-nova-sonic-mcp.git
cd sample-nova-sonic-mcp
```

### 2. Add Dental Receptionist Files

Copy all the provided files into your project:

```bash
# Copy configuration
cp dental-receptionist-config.js .

# Copy UI
cp dental-receptionist-ui.html public/index.html

# Copy deployment files
cp Dockerfile .
cp cloudformation-template.yaml deploy/
cp deploy.sh .
chmod +x deploy.sh
```

### 3. Update Your Server Code

Modify your `server.ts` to import and use the dental receptionist configuration:

```typescript
const { DENTAL_RECEPTIONIST_PROMPT } = require('./dental-receptionist-config.js');

socket.on('connection', (client) => {
  client.emit('systemPrompt', DENTAL_RECEPTIONIST_PROMPT);
  client.emit('voiceConfig', { voiceId: 'tiffany' });
});
```

### 4. Customize for Your Practice

Edit `dental-receptionist-config.js`:

```javascript
// Update practice information
- Location: City centre, near the main market area
+ Location: 123 Your Street, Your City

- Hours: Monday to Saturday, 9 AM to 7 PM
+ Hours: Your actual hours

// Update pricing
- Professional in-office whitening typically ranges from £300-£600
+ Professional in-office whitening typically ranges from $400-$800
```

Edit `public/index.html`:

```html
<!-- Add your logo -->
<img src="./your-logo.png" alt="Your Practice">
<h1>Your Practice Name</h1>

<!-- Update contact information -->
<span>Your Phone Number</span>
<span>Your Address</span>
```

### 5. Test Locally

```bash
npm install
npm run build
npm start

# Open http://localhost:3000
# Click the microphone button and speak to test
```

### 6. Deploy to AWS

```bash
# Make sure AWS CLI is configured
aws configure

# Run the automated deployment script
./deploy.sh production

# This will:
# - Build the Docker image
# - Push to ECR
# - Deploy CloudFormation stack
# - Set up ECS, ALB, and all infrastructure
```

The script will output your Application URL when complete!

## 🎨 Customization Guide

### Changing the Branding

**Colors**: Edit the CSS variables in `public/index.html`:

```css
:root {
  --primary-color: #1e88e5;      /* Change to your brand color */
  --secondary-color: #0d47a1;    /* Secondary brand color */
  --accent-color: #4fc3f7;       /* Accent color */
}
```

**Logo**: Replace the SVG or add your image:

```html
<div class="practice-logo">
  <img src="./logo.png" alt="Practice Logo" style="height: 50px;">
  <h1>Your Practice Name</h1>
</div>
```

**Practice Info**: Update the header:

```html
<div class="practice-info">
  <div class="practice-info-item">
    <span>555-123-4567</span>
  </div>
  <div class="practice-info-item">
    <span>Your Address</span>
  </div>
  <div class="practice-info-item">
    <span>Your Hours</span>
  </div>
</div>
```

### Modifying the Knowledge Base

The knowledge base in `dental-receptionist-config.js` is comprehensive but should be customized:

**Add Services**:
```javascript
### Specialized Services
- Sleep apnea treatment
- TMJ therapy
- Laser dentistry
```

**Update Pricing**:
```javascript
- Teeth whitening: $300-$600
+ Teeth whitening: Your actual prices
```

**Add Practice Policies**:
```javascript
## Payment Policies
- Payment due at time of service
- We accept CareCredit
- Senior discounts available
```

**Customize Voice and Tone**:
```javascript
// More formal
"You are a professional medical receptionist..."

// More casual
"You are a friendly dental receptionist who makes patients feel at ease..."
```

### Adding Custom Features

**Appointment Integration**: Connect to your scheduling system:

```typescript
socket.on('scheduleAppointment', async (data) => {
  // Call your practice management software API
  const response = await yourPMSAPI.createAppointment(data);
  socket.emit('appointmentConfirmed', response);
});
```

**CRM Integration**: Sync patient data:

```typescript
socket.on('patientInfo', async (data) => {
  // Save to your CRM/database
  await db.patients.upsert(data);
});
```

**SMS Notifications**: Add Twilio integration:

```typescript
const twilio = require('twilio');

socket.on('appointmentScheduled', async (data) => {
  await twilioClient.messages.create({
    body: `Appointment confirmed for ${data.date} at ${data.time}`,
    to: data.phoneNumber,
    from: yourTwilioNumber
  });
});
```

## 🏗️ Architecture

```
┌─────────────┐
│   Patient   │
│  (Browser)  │
└──────┬──────┘
       │ WebSocket
       │
┌──────▼──────────────────────────┐
│   Application Load Balancer     │
│         (AWS ALB)               │
└──────┬──────────────────────────┘
       │
┌──────▼──────────────────────────┐
│      ECS Fargate Tasks          │
│   (Node.js + Socket.IO)         │
│                                 │
│  - Dental Receptionist Config   │
│  - Audio Streaming              │
│  - Patient Data Collection      │
└──────┬──────────────────────────┘
       │
┌──────▼──────────────────────────┐
│     Amazon Bedrock              │
│     (Nova Sonic Model)          │
│                                 │
│  - Speech-to-Speech             │
│  - Natural Conversation         │
└─────────────────────────────────┘
```

## 💰 Cost Estimate

Monthly costs for a small practice (estimates for US-East-1):

| Service | Usage | Cost |
|---------|-------|------|
| ECS Fargate | 1 task, 24/7 | ~$15 |
| Application Load Balancer | Standard | ~$23 |
| Amazon Bedrock (Nova Sonic) | 1,000 conversations | ~$50-100 |
| Data Transfer | 100GB | ~$9 |
| CloudWatch Logs | 10GB | ~$5 |
| **Total** | | **~$102-127/month** |

**Cost Optimization Tips**:
- Use auto-scaling to scale down during off-hours
- Enable Fargate Spot for non-production (70% savings)
- Use CloudFront for static assets
- Implement conversation caching

## 🔒 Security & Compliance

### HIPAA Compliance Considerations

This architecture provides a strong foundation for HIPAA compliance:

✅ **Encryption in Transit** - TLS/SSL for all connections  
✅ **Encryption at Rest** - ECS encryption, encrypted logs  
✅ **Access Controls** - IAM roles, security groups  
✅ **Audit Logging** - CloudWatch logs, CloudTrail  
✅ **Network Isolation** - VPC, private subnets optional

⚠️ **Additional Requirements**:
- Sign AWS Business Associate Agreement (BAA)
- Enable CloudTrail for all API calls
- Implement additional access controls as needed
- Regular security assessments
- Data retention policies

### Best Practices

1. **Enable HTTPS** - Use ACM certificate (included in CloudFormation)
2. **Restrict Access** - Use security groups to limit IP ranges
3. **Enable WAF** - Add Web Application Firewall for additional protection
4. **Monitor Logs** - Set up CloudWatch alarms for suspicious activity
5. **Rotate Credentials** - Use AWS Secrets Manager
6. **Regular Updates** - Keep dependencies and Docker images updated

## 📊 Monitoring & Maintenance

### View Logs

```bash
# Stream application logs
aws logs tail /ecs/dental-receptionist --follow

# Search for errors
aws logs filter-log-events \
  --log-group-name /ecs/dental-receptionist \
  --filter-pattern "ERROR"
```

### Monitor Performance

Access CloudWatch dashboard to view:
- Request count
- Error rate
- Response time
- CPU/Memory utilization
- WebSocket connections

### Update Deployment

```bash
# Make your changes to code or config
# Then re-run deployment script
./deploy.sh production
```

## 🧪 Testing

### Manual Testing

1. Open the application URL
2. Click the call button
3. Speak naturally: "Hello, I'd like to schedule a check-up"
4. Observe the response and information collection

### Load Testing

```bash
# Install Apache Bench
apt-get install apache2-utils

# Test 100 requests, 10 concurrent
ab -n 100 -c 10 http://your-alb-url/
```

## 🐛 Troubleshooting

### Common Issues

**Q: "Microphone not working"**  
A: Ensure browser has microphone permissions. Use HTTPS for production.

**Q: "Bedrock Access Denied"**  
A: Enable Bedrock model access in AWS Console → Bedrock → Model access

**Q: "WebSocket connection fails"**  
A: Check security groups allow traffic on port 3000. Verify ALB configuration.

**Q: "High latency"**  
A: Increase ECS task CPU/memory. Consider enabling CloudFront.

**Q: "Container fails health checks"**  
A: Check logs with `aws logs tail /ecs/dental-receptionist --follow`

### Debug Mode

Enable detailed logging in your server:

```typescript
// Add to server.ts
const DEBUG = process.env.DEBUG === 'true';

if (DEBUG) {
  console.log('Request details:', details);
}
```

## 🤝 Contributing

Contributions are welcome! Areas for improvement:

- Multi-language support
- Integration with popular Practice Management Systems
- Enhanced analytics and reporting
- Voice biometrics for patient identification
- Automated appointment booking
- Integration with calendar systems

## 📚 Additional Resources

- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [Amazon Nova Sonic](https://aws.amazon.com/bedrock/nova/)
- [Original Nova Sonic MCP Sample](https://github.com/aws-samples/sample-nova-sonic-mcp)
- [ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [WebSocket on AWS](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api.html)

## 📄 License

This project is licensed under the ISC License - see the LICENSE file for details.

## 🙏 Acknowledgments

Built on top of the excellent [Nova Sonic MCP Sample](https://github.com/aws-samples/sample-nova-sonic-mcp) by AWS.

---

**Questions or Issues?**  
Open an issue in the repository or contact your AWS Solutions Architect.

**Want Professional Support?**  
Contact AWS Professional Services for help with deployment, customization, and integration.
