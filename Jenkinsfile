pipeline {
    environment {
        DOCKER_ID = "poissonchat13"
        DOCKER_IMAGE = "spring-petclinic-visits-service"
        JMETER_TAG = "vist"
        JENK_TOOLBOX = "/opt/jenkins"
    }
    agent any
    stages {
        stage('Recuperation de la version Majeur') {
            steps {
                script {
                    VERSION_MAJEUR = sh(script: 'head -n 5 ./README.md | tail -n 1', returnStdout: true).trim()
                    env.DOCKER_TAG = "${VERSION_MAJEUR}.${BUILD_ID}"
                }
            }
        }
        stage('Docker Build Dev') {
            steps {
                sh '''
                docker build -t localhost:5000/$DOCKER_IMAGE:latest .
                docker push localhost:5000/$DOCKER_IMAGE:latest 
                '''
            }
        }
        stage('Deploiement Developpement') {
            environment {
                KUBECONFIG = credentials("confkub")
                BDD_PASS = credentials("bdd_pass_dev")
            }
            steps {
                sh '''
                $JENK_TOOLBOX/ctrl/checkNamespaceUse.sh developpement
                cp -r ${JENK_TOOLBOX}/helm/* ./
                rm -Rf .kube
                mkdir .kube
                ls
                cat $KUBECONFIG > .kube/config
                helm install petclinic-dev petclinic-dev --values=./petclinic-dev/value.yaml --set $JMETER_TAG.repo=localhost:5000 --set petclinic.bdpwd=$BDD_PASS
                sleep 120 
                '''
            }
        }
        stage('Test Acceptance') {
            steps {
                sh '$JENK_TOOLBOX/ctrl/checkpod.sh developpement'
            }
        }
        stage('Test Performance Jmeter') {
            steps {
                sh '''
                echo "$DOCKER_IMAGE:$DOCKER_TAG $(date +"%Y-%m-%d-%H-%M")" >> $JENK_TOOLBOX/logs/jmeter-commit-version.log
                $JENK_TOOLBOX/apache-jmeter/bin/jmeter -n -t $JENK_TOOLBOX/test/petclinic_test_plan.jmx -l $JENK_TOOLBOX/test/petclinic_result_test.jtl
                '''
            }
        }
        stage('Build Jmeter pour report') {
            environment {
                API_TOKEN = credentials("API_TOKEN")
            }
            steps {
                script {
                    def displayName = "${JMETER_TAG}-${DOCKER_TAG}"
                    def description = "Build trigger by the job ${JOB_NAME}  On the microservice ${DOCKER_IMAGE} "

                    def buildResult = build job: 'jmeter-perf-central', 
                                           wait: true, 
                                           propagate: false

                    def jobUrl = buildResult.getAbsoluteUrl()

                    echo "Job URL: ${jobUrl}"
                    
                    sh """
                    curl -X POST -u ${API_TOKEN} -F 'json={"displayName":"${displayName}","description":"${description}"}' \
                    '${jobUrl}configSubmit'
                    """
                }
            }
        }
        stage('Demontage Env Dev') {
            environment {
                KUBECONFIG = credentials("confkub")
            }
            steps {
                sh '''
                rm -Rf .kube
                mkdir .kube
                ls
                cat $KUBECONFIG > .kube/config
                helm uninstall petclinic-dev
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
                docker tag localhost:5000/$DOCKER_IMAGE:latest $DOCKER_ID/$DOCKER_IMAGE:$DOCKER_TAG
                docker tag $DOCKER_ID/$DOCKER_IMAGE:$DOCKER_TAG $DOCKER_ID/$DOCKER_IMAGE:latest
                docker push $DOCKER_ID/$DOCKER_IMAGE:$DOCKER_TAG
                docker push $DOCKER_ID/$DOCKER_IMAGE:latest
                '''
            }
        }
    }
}
