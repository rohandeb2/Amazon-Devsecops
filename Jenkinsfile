pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
        timestamps()
    }

    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        IMAGE_NAME   = "rohan700/amazon"
        IMAGE_TAG    = "${env.BUILD_NUMBER}"
        DOCKER_CREDS = 'docker-cred'
    }

    stages {

        stage('Workspace Initialization') {
            steps {
                cleanWs()
            }
        }

        stage('Source Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/rohandeb2/Amazon-Devsecops.git'
            }
        }

        stage('Static Code Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh """
                        ${SCANNER_HOME}/bin/sonar-scanner \
                        -Dsonar.projectKey=amazon \
                        -Dsonar.projectName=amazon \
                        -Dsonar.sourceEncoding=UTF-8
                    """
                }
            }
        }

        stage('Quality Gate Enforcement') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true, credentialsId: 'sonar-token'
                }
            }
        }

        stage('Dependency Installation') {
            steps {
                sh 'npm ci'
            }
        }

        stage('Dependency Vulnerability Scan') {
            steps {
                dependencyCheck additionalArguments: '''
                    --scan ./ 
                    --format XML
                ''',
                odcInstallation: 'dp-check'

                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage('Filesystem Security Scan') {
            steps {
                sh 'trivy fs --severity HIGH,CRITICAL --exit-code 0 --format table -o trivy-fs-report.txt .'
            }
        }

        stage('Container Build') {
            steps {
                script {
                    sh """
                        docker build \
                        --no-cache \
                        -t ${IMAGE_NAME}:${IMAGE_TAG} \
                        -t ${IMAGE_NAME}:latest .
                    """
                }
            }
        }

        stage('Container Image Scan') {
            steps {
                sh """
                    trivy image \
                    --severity HIGH,CRITICAL \
                    --format json \
                    -o trivy-image.json \
                    ${IMAGE_NAME}:${IMAGE_TAG}

                    trivy image \
                    --severity HIGH,CRITICAL \
                    --format table \
                    -o trivy-image.txt \
                    ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

        stage('Push Image to Registry') {
            steps {
                script {
                    withCredentials([string(credentialsId: DOCKER_CREDS, variable: 'DOCKER_PASSWORD')]) {
                        sh """
                            echo ${DOCKER_PASSWORD} | docker login -u ${IMAGE_NAME.split('/')[0]} --password-stdin
                            docker push ${IMAGE_NAME}:${IMAGE_TAG}
                            docker push ${IMAGE_NAME}:latest
                        """
                    }
                }
            }
        }

        stage('Container Deployment') {
            steps {
                sh """
                    docker rm -f amazon || true
                    docker run -d \
                        --name amazon \
                        -p 80:80 \
                        --restart=always \
                        ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }
    }

    post {
        always {
            script {
                def buildStatus = currentBuild.currentResult
                def buildUser = currentBuild.getBuildCauses('hudson.model.Cause$UserIdCause')[0]?.userId ?: 'SCM Trigger'

                emailext (
                    subject: "Pipeline ${buildStatus}: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    body: """
                        <h3>CI/CD Pipeline Execution Summary</h3>
                        <p><b>Project:</b> ${env.JOB_NAME}</p>
                        <p><b>Build Number:</b> ${env.BUILD_NUMBER}</p>
                        <p><b>Status:</b> ${buildStatus}</p>
                        <p><b>Triggered By:</b> ${buildUser}</p>
                        <p><b>Build URL:</b> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    """,
                    to: 'rohandeb28@gmail.com',
                    mimeType: 'text/html',
                    attachmentsPattern: 'trivy-fs-report.txt,trivy-image.json,trivy-image.txt,dependency-check-report.xml'
                )
            }
        }
    }
}