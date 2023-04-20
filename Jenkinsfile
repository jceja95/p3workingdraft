pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', credentialsId: '<CREDS>', url: 'https://github.com/jceja95/p3workingdraft'
            }
        }
        stage('Terraform init') {
            steps {
                echo 'terraform init'
            }
        }
        stage('Terraform plan') {
            steps {
                echo 'terraform plan'
            }
        }
        stage('Terraform apply') {
            steps {
                echo 'terraform apply --auto-approve'
            }
        }
        
    }
}