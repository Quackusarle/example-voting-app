def buildAndPush(String serviceName, String buildNumber, String dockerhubUser) {
    echo "Building and pushing service: ${serviceName} to Docker Hub"
    def imageNameWithTag = "${dockerhubUser}/${serviceName}:${buildNumber}"
    dir(serviceName) {
        sh "docker build -t ${imageNameWithTag} ."
    }
    sh "docker push ${imageNameWithTag}"
}

def buildAndPushAll(String buildNumber, String dockerhubUser) {
    def allServices = ['vote', 'result', 'worker']
    parallel allServices.collectEntries { svc ->
        ["Building ${svc}": { buildAndPush(svc, buildNumber, dockerhubUser) }]
    }
}

pipeline {
    agent any
    parameters {
        choice(name: 'SERVICE_NAME', choices: ['vote', 'result', 'worker', 'ALL'], description: 'Select a service')
    }
    
    environment {
        DOCKERHUB_USER = 'quackusarle' 
        GITOPS_REPO_USER = 'Quackusarle'
        GITOPS_REPO_NAME = 'example-voting-app'
        GITOPS_REPO_BRANCH = 'main'
    }
    
    stages {
        stage('Checkout Code') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${GITOPS_REPO_BRANCH}"]],
                    userRemoteConfigs: [[
                        credentialsId: 'github-credentials',
                        url: "https://github.com/${GITOPS_REPO_USER}/${GITOPS_REPO_NAME}.git"
                    ]]
                ])
            }
        }
        
        stage('Build and Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    script {
                        sh "echo ${DOCKER_PASS} | docker login --username ${DOCKER_USER} --password-stdin"
                        if (params.SERVICE_NAME == 'ALL') {
                            buildAndPushAll(BUILD_NUMBER, DOCKERHUB_USER)
                        } else {
                            buildAndPush(params.SERVICE_NAME, BUILD_NUMBER, DOCKERHUB_USER)
                        }
                    }
                }
            }
        }
        
        stage('Update Helm Values (GitOps Trigger)') {
            when {
                expression { params.SERVICE_NAME != 'ALL' }
            }
            steps {
                withCredentials([string(credentialsId: 'github-credentials', variable: 'GITHUB_TOKEN')]) {
                    script {
                        sh 'git config --global user.email "jenkins-ci@bot.com"'
                        sh 'git config --global user.name "Jenkins CI Bot"'

                        def valuesFile = "voting-app-chart/values.yaml"
                        def newTag = "${BUILD_NUMBER}"
                        def newRepo = "${DOCKERHUB_USER}/${params.SERVICE_NAME}"
                        
                        echo "Updating ${valuesFile} for service '${params.SERVICE_NAME}'"
                        
                        sh "sed -i -e '/^${params.SERVICE_NAME}:/,/^[a-zA-Z]/{s|  repository: .*|  repository: \"${newRepo}\"|}' ${valuesFile}"
                        sh "sed -i -e '/^${params.SERVICE_NAME}:/,/^[a-zA-Z]/{s|  tag: .*|  tag: \"${newTag}\"|}' ${valuesFile}"

                        sh "git add ${valuesFile}"
                        sh "git diff-index --quiet HEAD || git commit -m 'CI: Update Helm values for ${params.SERVICE_NAME} to version ${BUILD_NUMBER}'"
                        
                        def remoteUrlWithToken = "https://${GITOPS_REPO_USER}:${GITHUB_TOKEN}@github.com/${GITOPS_REPO_USER}/${GITOPS_REPO_NAME}.git"
                        
                        sh "git push ${remoteUrlWithToken} HEAD:${GITOPS_REPO_BRANCH}"
                    }
                }
            }
        }
    }
    
    post {
        always {
            sh 'docker logout'
        }
    }
}