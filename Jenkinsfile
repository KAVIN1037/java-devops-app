pipeline {
    agent any

    environment {
        IMAGE_NAME = 'daddykavin/java-devops-app'
        SONAR_SERVER = 'SonarQube'
        GIT_REPO = 'https://github.com/KAVIN1037/java-devops-gitops.git'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Maven Build') {
            steps {
                sh 'mvn -B clean package -DskipTests'
            }
        }

        stage('Unit Test') {
            steps {
                sh 'mvn -B test'
            }
            post {
                always {
                    junit allowEmptyResults: true,
                          testResults: 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('SonarQube Cloud Analysis') {
            steps {
                withCredentials([string(
                    credentialsId: 'sonarcloud-token',
                    variable: 'SONAR_TOKEN'
                )]) {
                    sh '''
                        set +x
                        export SONAR_SCANNER_JAVA_OPTS="-Xmx2048m"
                        export MAVEN_OPTS="-Xmx2048m"

                        mvn -B org.sonarsource.scanner.maven:5.3.0.6276:sonar \
                          -Dsonar.organization=kavin1037 \
                          -Dsonar.projectKey=KAVIN1037_java-devops-app \
                          -Dsonar.host.url=https://sonarcloud.io \
                          -Dsonar.token="$SONAR_TOKEN" \
                          -Dsonar.scanner.javaOpts="-Xmx2048m"
                    '''
                }
            }
        }
      stage('Image Versioning') {
            steps {
                script {
                    env.IMAGE_TAG = "${env.BUILD_NUMBER}"
                    echo "Docker image tag: ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t $IMAGE_NAME:$IMAGE_TAG .'
            }
        }

        stage('Push Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        set +x
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push "$IMAGE_NAME:$IMAGE_TAG"
                        docker logout
                    '''
                }
            }
        }

        stage('Update Helm Configuration') {
            steps {
                dir('gitops') {
                    git branch: 'main',
                        credentialsId: 'github-creds',
                        url: "${GIT_REPO}"

                    sh '''
                        sed -i -E "s/(tag:[[:space:]]*)\\"[^\\"]+\\"/\\1\\"${BUILD_NUMBER}\\"/" helm/values.yaml
                        grep -n 'tag:' helm/values.yaml
                    '''
                }
            }
        }

        stage('Commit Deployment Change') {
            steps {
                dir('gitops') {
                    withCredentials([usernamePassword(
                        credentialsId: 'github-creds',
                        usernameVariable: 'GIT_USER',
                        passwordVariable: 'GIT_TOKEN'
                    )]) {
                        sh '''
                            set +x
                            git config user.name "Jenkins CI"
                            git config user.email "jenkins@example.com"
                            git add helm/values.yaml

                            if ! git diff --cached --quiet; then
                                git commit -m "Update image version to ${BUILD_NUMBER}"
                                ASKPASS=$(mktemp)
                                trap 'rm -f "$ASKPASS"' EXIT
                                printf '%s\\n' \
                                  '#!/bin/sh' \
                                  'case "$1" in' \
                                  '  *Username*) echo "$GIT_USER" ;;' \
                                  '  *) echo "$GIT_TOKEN" ;;' \
                                  'esac' > "$ASKPASS"
                                chmod 700 "$ASKPASS"
                                GIT_ASKPASS="$ASKPASS" GIT_TERMINAL_PROMPT=0 git push origin HEAD:main
                            else
                                echo "No Helm changes to commit."
                            fi
                        '''
                    }
                }
            }
        }
    }
}

