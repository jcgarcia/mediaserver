pipeline {
    agent any
    
    environment {
        NODE_VERSION = '18'
        AWS_DEFAULT_REGION = 'eu-west-2'
        ECR_REPOSITORY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/mediaserver"
        IMAGE_TAG = "${BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Setup Node.js') {
            steps {
                sh '''
                    # Install Node.js and pnpm
                    curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
                    sudo apt-get install -y nodejs
                    npm install -g pnpm
                '''
            }
        }
        
        stage('Install Dependencies') {
            steps {
                sh 'pnpm install --frozen-lockfile'
            }
        }
        
        stage('Run Tests') {
            steps {
                sh 'pnpm test'
            }
            post {
                always {
                    publishTestResults testResultsPattern: 'test-results.xml'
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    def image = docker.build("${ECR_REPOSITORY}:${IMAGE_TAG}")
                    docker.withRegistry("https://${ECR_REPOSITORY}", 'ecr:eu-west-2:aws-credentials') {
                        image.push()
                        image.push('latest')
                    }
                }
            }
        }
        
        stage('Deploy Infrastructure') {
            when {
                branch 'main'
            }
            steps {
                sh '''
                    # Install Terraform and Ansible
                    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
                    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
                    sudo apt-get update && sudo apt-get install terraform
                    pip3 install ansible
                    
                    # Deploy using Ansible
                    ansible-galaxy install -r ansible/requirements.yml
                    ansible-playbook ansible/playbooks/deploy.yml -e image_tag=${IMAGE_TAG}
                '''
            }
        }
        
        stage('Health Check') {
            when {
                branch 'main'
            }
            steps {
                sh '''
                    # Wait for deployment to be ready
                    sleep 60
                    
                    # Check service health
                    ansible-playbook ansible/playbooks/manage.yml -e action=status
                '''
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            slackSend channel: '#deployments', 
                     color: 'good', 
                     message: "✅ MediaServer deployment successful - Build ${BUILD_NUMBER}"
        }
        failure {
            slackSend channel: '#deployments', 
                     color: 'danger', 
                     message: "❌ MediaServer deployment failed - Build ${BUILD_NUMBER}"
        }
    }
}
