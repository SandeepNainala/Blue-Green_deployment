pipeline {
    agent any

    tools {
        maven 'Maven 3'
        jdk 'JDK 11'
    }
    parameters {
        choice(name: 'DEPLOY_ENV', choices: ['blue', 'green'], description: 'Choose which environment to deploy: Blue or Green')
        choice(name: 'DOCKER_TAG', choices: ['blue', 'green'], description: 'Choose the Docker image tag for the deployment')
        booleanParam(name: 'SWITCH_TRAFFIC', defaultValue: false, description: 'Switch traffic between Blue and Green')
    }

    environment {
        IMAGE_NAME = 'sandeepnainala/bankapp'
        TAG = 'v1.0'
        SCANNER_HOME = tool 'sonar-scanner'
    }

    options {
        ansiColor('xterm')
        timeout(time: 1, unit: 'HOURS')
    }

    stages {
        stage('clean workspace'){
            steps{
                cleanWs()
            }
        }
        stage('Git Checkout') {
            steps {
               git branch: 'main', credentialsId: 'git-cred', url: 'https://github.com/SandeepNainala/Blue-Green_deployment.git'
            }
        }
        stage('Compile') {
            steps {
                sh "mvn compile"
            }
        }
        stage('Tests') {
            steps {
                sh "mvn test Dskiptests=true"
            }
        }
        stage('Trivy FS Scan') {
            steps {
                sh " trivy fs --format table -o fs.html ."
            }
        }
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh "${SCANNER_HOME}/bin/sonar-scanner \
                        -Dsonar.projectKey=Blue-Green_deployment \
                        -Dsonar.projectName=Blue-Green_deployment \
                        -Dsonar.java.binaries=target "
                }
            }
        }
        stage("Quality Gate Check"){
           steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token'
                }
            }
        }
        stage('Build') {
            steps {
                sh "mvn clean package -DskipTests=true"
            }
        }
        stage('Publish Artifacts') {
            steps {
                withMaven(globalMavenSettingsConfig: 'maven-settings', maven: 'Maven 3' globalMavenSettingsConfig: '', traceability: false) {
                    sh "mvn deploy -DskipTests=true"
                }
            }
        }
        stage('Docker Build') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker-cred') {
                        sh "docker build -t ${IMAGE_NAME}:${TAG} ."
                    }
                }
            }
        }
    post {
        always {
            echo 'Cleaning up...'
        }
    }
}