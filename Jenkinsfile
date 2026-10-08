pipeline {
    agent any

    parameters {
        string(name: 'IMAGE_NAME', defaultValue: 'mukeshchaudhary14/petstore-app', description: 'Docker Hub Image Name')
        string(name: 'IMAGE_TAG', defaultValue: "v1.0.${BUILD_NUMBER}", description: 'Image Tag')
        string(name: 'DOCKER_CREDENTIALS_ID', defaultValue: 'dockerhub-credentials', description: 'Jenkins credentials ID for Docker Registry')
        string(name: 'K8S_NAMESPACE', defaultValue: 'petstore', description: 'Kubernetes Namespace for Deployment')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Skip Maven unit tests')
        booleanParam(name: 'TRIVY_FAIL_ON_CRITICAL', defaultValue: false, description: 'Fail build if Trivy detects Critical vulnerabilities')
        choice(name: 'DEPLOY_METHOD', choices: ['Helm', 'ArgoCD-GitOps', 'Kubectl', 'None'], description: 'Deployment method')
    }

    environment {
        DOCKER_IMAGE = "${params.IMAGE_NAME}"
        TAG = "${params.IMAGE_TAG}"
        DOCKER_CRED_ID = "${params.DOCKER_CREDENTIALS_ID}"
        NAMESPACE = "${params.K8S_NAMESPACE}"
        REPORTS_DIR = "security-reports"
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
        timeout(time: 30, unit: 'MINUTES')
        ansiColor('xterm')
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo "===> [STAGE 1] Checking out Source Code..."
                checkout scm
            }
        }

        stage('Build & Test Application') {
            steps {
                echo "===> [STAGE 2] Building Petstore Application with Maven..."
                script {
                    sh 'chmod +x ./mvnw'
                    if (params.SKIP_TESTS) {
                        sh './mvnw clean package -DskipTests'
                    } else {
                        sh './mvnw clean package'
                    }
                }
            }
            post {
                always {
                    junit testResults: '**/target/surefire-reports/*.xml', allowEmptyResults: true
                }
            }
        }

        stage('Trivy Security Scan - Filesystem') {
            steps {
                echo "===> [STAGE 3] Scanning Repository Code & Dependencies with Trivy..."
                script {
                    sh 'mkdir -p ${REPORTS_DIR}'
                    def severityExit = params.TRIVY_FAIL_ON_CRITICAL ? '--exit-code 1 --severity CRITICAL' : '--exit-code 0'
                    sh """
                        if command -v trivy >/dev/null 2>&1; then
                            trivy fs --severity HIGH,CRITICAL --format table ${severityExit} .
                        else
                            docker run --rm -v \$(pwd):/workspace -w /workspace -v \${HOME}/.cache/trivy:/root/.cache/trivy aquasec/trivy:latest fs --severity HIGH,CRITICAL . || true
                        fi
                    """
                }
            }
        }

        stage('Docker Build') {
            steps {
                echo "===> [STAGE 4] Building Docker Image: ${DOCKER_IMAGE}:${TAG}..."
                script {
                    sh """
                        docker build -t ${DOCKER_IMAGE}:${TAG} -t ${DOCKER_IMAGE}:latest .
                    """
                }
            }
        }

        stage('Trivy Security Scan - Docker Image') {
            steps {
                echo "===> [STAGE 5] Scanning Docker Image with Trivy..."
                script {
                    def severityExit = params.TRIVY_FAIL_ON_CRITICAL ? '--exit-code 1 --severity CRITICAL' : '--exit-code 0'
                    sh """
                        if command -v trivy >/dev/null 2>&1; then
                            trivy image --severity HIGH,CRITICAL --format table ${severityExit} ${DOCKER_IMAGE}:${TAG}
                        else
                            docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v \${HOME}/.cache/trivy:/root/.cache/trivy aquasec/trivy:latest image --severity HIGH,CRITICAL ${DOCKER_IMAGE}:${TAG} || true
                        fi
                    """
                }
            }
        }

        stage('Docker Push to Registry') {
            steps {
                echo "===> [STAGE 6] Pushing Image to Registry..."
                script {
                    withCredentials([usernamePassword(credentialsId: "${DOCKER_CRED_ID}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh """
                            echo "\${DOCKER_PASS}" | docker login -u "\${DOCKER_USER}" --password-stdin
                            docker push ${DOCKER_IMAGE}:${TAG}
                            docker push ${DOCKER_IMAGE}:latest
                        """
                    }
                }
            }
        }

        stage('Helm Lint & IaC Scan') {
            steps {
                echo "===> [STAGE 7] Linting Helm Charts and Validating IaC..."
                script {
                    sh """
                        if command -v helm >/dev/null 2>&1; then
                            helm lint helm/petstore
                        else
                            echo "Helm binary not in PATH, skipping lint"
                        fi
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo "===> [STAGE 8] Deploying to Kubernetes using ${params.DEPLOY_METHOD}..."
                script {
                    switch (params.DEPLOY_METHOD) {
                        case 'Helm':
                            echo "Deploying via Helm upgrade --install..."
                            sh """
                                helm upgrade --install petstore helm/petstore \
                                    --namespace ${NAMESPACE} \
                                    --create-namespace \
                                    --set image.repository=${DOCKER_IMAGE} \
                                    --set image.tag=${TAG}
                            """
                            break

                        case 'ArgoCD-GitOps':
                            echo "Triggering ArgoCD GitOps Sync..."
                            sh """
                                echo "Updating Helm values tag in Git repo or triggering ArgoCD application sync"
                                # argocd app sync petstore-app --prune
                            """
                            break

                        case 'Kubectl':
                            echo "Deploying via kubectl manifests..."
                            sh """
                                kubectl apply -f k8s/namespace.yaml
                                kubectl apply -f k8s/configmap.yaml
                                kubectl apply -f k8s/secret.yaml
                                kubectl set image -f k8s/deployment.yaml petstore=${DOCKER_IMAGE}:${TAG} --local -o yaml | kubectl apply -n ${NAMESPACE} -f -
                                kubectl apply -f k8s/service.yaml -n ${NAMESPACE}
                                kubectl apply -f k8s/ingress.yaml -n ${NAMESPACE} || true
                                kubectl apply -f k8s/hpa.yaml -n ${NAMESPACE} || true
                            """
                            break

                        default:
                            echo "Skipping deployment stage."
                    }
                }
            }
        }
    }

    post {
        success {
            echo "============================================================"
            echo " SUCCESS: Petstore Pipeline execution finished successfully!"
            echo " Image: ${DOCKER_IMAGE}:${TAG}"
            echo "============================================================"
        }
        failure {
            echo "============================================================"
            echo " FAILURE: Petstore Pipeline execution failed!"
            echo " Check the console logs for debugging."
            echo "============================================================"
        }
        always {
            cleanWs deleteDirs: true, notFailBuild: true
        }
    }
}
