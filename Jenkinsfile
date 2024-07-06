pipeline {
    environment {
        DOCKER_ID = "poissonchat13"
        DOCKER_IMAGE = "spring-petclinic-visits-service"
    }
    agent any

    stages {
        stage('Recuperation de la version Majeur') {
            steps {
                script {
                    VERSION_MAJEUR = sh(script: 'head -n 1 ./README.md', returnStdout: true).trim()
                    env.DOCKER_TAG = "${VERSION_MAJEUR}.v.${BUILD_ID}"
                }
            }
        }
        stage('Maven build test') {
            steps {
                sh './mvnw clean package'
            }
        }
        stage('Docker Build Dev') {
            environment {
                DOCKER_PASS = credentials("DOCKER_HUB_PASS")
            }
            steps {
                sh '''
                docker build -t localhost:5000/$DOCKER_IMAGE:latest-dev .
                sleep 10
                '''
            }
        }
        stage('Deploiement Developpement') {
            environment {
                KUBECONFIG = credentials("config")
            }
            steps {
                sh '''
                cp -r /opt/helm/* ./
                rm -Rf .kube
                mkdir .kube
                ls
                cat $KUBECONFIG > .kube/config
                helm upgrade --install app spring-pet-clinic-litecloud --values=./spring-pet-clinic-litecloud/value.yaml
                sleep 120 
                '''
            }
        }
        stage('Test Acceptance') {
            steps {
                sh 'curl localhost:30105'
            }
        }
        stage('Test Performance Jmeter') {
            steps {
                sh '''
                date >> /opt/custom/test/jmeter-commit-version.log
                echo "$DOCKER_IMAGE:$DOCKER_TAG" >> /opt/custom/test/jmeter-commit-version.log
                jmeter -n -t /opt/custom/test/petclinic_test_plan.jmx -l /opt/custom/test/petclinic_result_test.jtl
                '''
            }
        }
        stage('Demontage Env Dev') {
            environment {
                KUBECONFIG = credentials("config")
            }
            steps {
                sh '''
                rm -Rf .kube
                mkdir .kube
                ls
                cat $KUBECONFIG > .kube/config
                helm uninstall app 
                '''
            }
        }
        stage('Push Image pour prod') {
            environment {
                DOCKER_PASS = credentials("DOCKER_HUB_PASS")
            }
            steps {
                sh '''
                docker login -u $DOCKER_ID -p $DOCKER_PASS
                docker tag localhost:5000/$DOCKER_IMAGE:latest-dev $DOCKER_ID/$DOCKER_IMAGE:$DOCKER_TAG
                docker tag $DOCKER_ID/$DOCKER_IMAGE:$DOCKER_TAG $DOCKER_ID/$DOCKER_IMAGE:latest
                docker push $DOCKER_ID/$DOCKER_IMAGE:$DOCKER_TAG
                docker push $DOCKER_ID/$DOCKER_IMAGE:latest
                '''
            }
        }
    }
}
