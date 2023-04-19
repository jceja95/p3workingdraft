pipeline {
    environment {
        registry = 'jceja95/project3draft'
        registryCredentials = 'docker'
        cluster_name = 'skillstorm'
        namespace = 'jesseceja'
    }
  agent {
    node {
      label 'docker'
    }

  }
  stages {
    stage('Git') {
      steps {
        git(url: 'https://github.com/jceja95/p3workingdraft', branch: 'main')
      }
    }
stage('Build Stage') {
    steps {
        script {
            dockerImage = docker.build(registry)
        }
      }
    }
stage('Deploy Stage') {
    steps {
        script {
           docker.withRegistry('', registryCredentials) {
                dockerImage.push()
            }
          }
        }
      }
stage('Kubernetes') {
  steps {
    withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'AWS', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
      sh "aws eks update-kubeconfig --region us-east-1 --name ${cluster_name}"
      script{
        try{
          sh "kubectl create namespace ${namespace}"
        }catch (Exception e) {
            echo "Exception handled"
        }
        }
        sh "kubectl apply -f deployment.yaml -n ${namespace}"
        sh "kubectl -n ${namespace} rollout restart deployment flaskcontainer"
        }
      }
    }
  }
}