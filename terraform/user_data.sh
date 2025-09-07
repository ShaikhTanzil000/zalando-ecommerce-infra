#!/bin/bash
# User data script for application bootstrap

# Set up logging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Update the system
yum update -y

# Install Node.js 18 LTS
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs git docker

# Start Docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Create simple Node.js app
mkdir -p /opt/zalando-app
cat > /opt/zalando-app/app.js << 'EOF'
const express = require('express');
const app = express();
const port = 80;

app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    hostname: require('os').hostname()
  });
});

app.get('/', (req, res) => {
  res.status(200).json({ 
    message: 'Welcome to Zalando E-commerce!', 
    hostname: require('os').hostname()
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`App listening on port ${port}`);
});
EOF

cat > /opt/zalando-app/package.json << 'EOF'
{
  "name": "zalando-app",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": { "start": "node app.js" },
  "dependencies": { "express": "^4.18.2" }
}
EOF

# Install dependencies and start app
cd /opt/zalando-app
npm install

# Create systemd service
cat > /etc/systemd/system/zalando-app.service << 'EOF'
[Unit]
Description=Zalando App
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/zalando-app
ExecStart=/usr/bin/node app.js
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

chown -R ec2-user:ec2-user /opt/zalando-app
systemctl daemon-reload
systemctl enable zalando-app
systemctl start zalando-app
