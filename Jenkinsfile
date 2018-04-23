pipeline {
  agent any
  stages {
    stage('build') {
      steps {
        echo 'step 1'
        withMaven(jdk: '1.8', maven: '3.5.2') {
            // Run the maven build
            sh "mvn package"
        }
      }
    }
  }
  post {
    always {
      echo 'done'
    }
  }
}
