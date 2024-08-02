pipeline {
  agent { label 'master' }
  stages {
    stage('Prepare') {
      steps {
        script {
          env.UNAME = sh (script: 'git show -s --pretty=\'%an\'', returnStdout: true).trim()
          env.UEMAIL = sh (script: 'git show -s --pretty=\'%ae\'', returnStdout: true).trim()
          env.COMMIT = sh (script: 'git log --pretty=format:\'%H\' -n 1', returnStdout: true).trim()
          env.SHORT_COMMIT = sh (script: 'git rev-parse --short HEAD', returnStdout: true).trim()
          env.ACCOUNT_ID = sh (script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
          env.AWS_REGION = sh (script: 'echo eu-central-1', returnStdout: true).trim()
        }
        echo "last commit by ${env.UNAME} - ${env.UEMAIL} on ${env.BRANCH_NAME} on ${env.SHORT_COMMIT}"
      }
    }
    stage('BUILD ALL') {
      parallel {
        stage('fpm-server') {
          stages {
            stage('Build-fpm-server') {
              steps {
                script {
                  try {
                      sh "DOCKER_BUILDKIT=0 docker buildx build -f Dockerfile --target fpm-server -t fpm-server:${env.SHORT_COMMIT} . --no-cache=true"
                  }
                  catch (e) {
                    sh "docker system prune --force"
                    emailext attachLog: true, body: "Your branch '${env.SHORT_COMMIT}' failed a jenkins build.\n Refer to ${env.RUN_DISPLAY_URL} for more details", subject: 'Jenkins Build Failed', to: "${env.UEMAIL}"
                    currentBuild.result = "FAILED"
                    error("failed to build app")
                  }
                }
              }
            }
            stage('Build-web-server') {
              steps {
                script {
                  try {
                      sh "DOCKER_BUILDKIT=0 docker buildx build -f Dockerfile --target web-server -t web-server:${env.SHORT_COMMIT} . --no-cache=true"
                  }
                  catch (e) {
                    sh "docker system prune --force"
                    emailext attachLog: true, body: "Your branch '${env.SHORT_COMMIT}' failed a jenkins build.\n Refer to ${env.RUN_DISPLAY_URL} for more details", subject: 'Jenkins Build Failed', to: "${env.UEMAIL}"
                    currentBuild.result = "FAILED"
                    error("failed to build app")
                  }
                }
              }
            }
            stage('Build-fpm-cron') {
              steps {
                script {
                  try {
                      sh "DOCKER_BUILDKIT=0 docker buildx build -f Dockerfile --target fpm-cron -t fpm-cron:${env.SHORT_COMMIT} . --no-cache=true"
                  }
                  catch (e) {
                    sh "docker system prune --force"
                    emailext attachLog: true, body: "Your branch '${env.SHORT_COMMIT}' failed a jenkins build.\n Refer to ${env.RUN_DISPLAY_URL} for more details", subject: 'Jenkins Build Failed', to: "${env.UEMAIL}"
                    currentBuild.result = "FAILED"
                    error("failed to build app")
                  }
                }
              }
            }
            stage('Push-fpm-server-2-ECR') {
                steps {
                  sh "aws ecr get-login-password --region ${env.AWS_REGION} | docker login --username AWS --password-stdin ${env.ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"
                  sh "docker tag fpm-server:${env.SHORT_COMMIT} ${env.ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/fpm-server:${env.SHORT_COMMIT}"
                  sh "docker push ${env.ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/fpm-server:${env.SHORT_COMMIT}"
                  sh "docker system prune --force"
                }
              }
            stage('Push-web-server-2-ECR') {
                steps {
                  sh "aws ecr get-login-password --region ${env.AWS_REGION} | docker login --username AWS --password-stdin ${env.ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"
                  sh "docker tag web-server:${env.SHORT_COMMIT} ${env.ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/web-server:${env.SHORT_COMMIT}"
                  sh "docker push ${env.ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/web-server:${env.SHORT_COMMIT}"
                  sh "docker system prune --force"
                }
              }
            stage('Push-fpm-cron-2-ECR') {
                steps {
                  sh "aws ecr get-login-password --region ${env.AWS_REGION} | docker login --username AWS --password-stdin ${env.ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"
                  sh "docker tag fpm-cron:${env.SHORT_COMMIT} ${env.ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/fpm-cron:${env.SHORT_COMMIT}"
                  sh "docker push ${env.ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/fpm-cron:${env.SHORT_COMMIT}"
                  sh "docker system prune --force"
                }
              }
            stage('Deploy-to-Prod') {
                agent { label 'docker-compose' }
                when { branch 'release' }
                steps {
                  sh "aws ecr get-login-password --region ${env.AWS_REGION} | docker login --username AWS --password-stdin ${env.ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"
                  sh ""
                  sh "docker system prune --force"
                }
              }
          }
        }
      }
    }
    stage('CleanUp') {
      steps {
        sh "docker rmi mtb-banking-admin-web:${env.SHORT_COMMIT} 069386304408.dkr.ecr.${env.AWS_REGION}.amazonaws.com/mtb-banking-admin-web:${env.SHORT_COMMIT} -f"
        sh "docker rmi mtb-banking-admin-api:${env.SHORT_COMMIT} 069386304408.dkr.ecr.${env.AWS_REGION}.amazonaws.com/mtb-banking-admin-api:${env.SHORT_COMMIT} -f"
      }
    }
  }
  post {
    always {
      sh "docker system prune --force --all"
    }
    failure {
        emailext attachLog: true, body: "Your branch '${env.SHORT_COMMIT}' failed a jenkins build.\n Refer to ${env.RUN_DISPLAY_URL} for more details", subject: 'Jenkins Build Failed', to: "${env.UEMAIL}"
    }
  }
}
