pipeline {
    agent any

    environment {
        IMAGE_NAME = 'daddykavin/java-devops-app'
        SONAR_SERVER = 'SonarQube'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Maven Build') {
            steps {
                bat 'mvn -B clean package -DskipTests'
            }
        }

        stage('Unit Test') {
            steps {
                bat 'mvn -B test'
            }
            post {
                always {
                    junit allowEmptyResults: true,
                          testResults: 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONAR_SERVER}") {
                    bat 'mvn -B sonar:sonar'
                }
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    env.IMAGE_TAG = "${env.BUILD_NUMBER}"
                }
                bat 'docker build -t %IMAGE_NAME%:%IMAGE_TAG% .'
            }
        }

        stage('Push Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    bat 'echo %DOCKER_PASS% | docker login -u %DOCKER_USER% --password-stdin'
                    bat 'docker push %IMAGE_NAME%:%IMAGE_TAG%'
                    bat 'docker logout'
                }
            }
        }

        stage('Update Helm Configuration') {
            steps {
                bat '''
                powershell -NoProfile -Command "(Get-Content helm-chart/values.yaml -Raw) -replace 'tag: \\"[^\\"]+\\"', ('tag: \\"' + $env:BUILD_NUMBER + '\\"') | Set-Content helm-chart/values.yaml"
                '''
            }
        }

        stage('Commit Deployment Change') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'github-creds',
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_TOKEN'
                )]) {
                    bat '''
                    git config user.name "Jenkins CI"
                    git config user.email "jenkins@example.com"
                    git add helm-chart/values.yaml
                    git commit -m "Update image version to %BUILD_NUMBER%" || exit /b 0
                    git push origin HEAD:main
                    '''
                }
            }
        }
    }
}
