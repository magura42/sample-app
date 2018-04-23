pipeline {
  agent {
    any
  }
  stage('build') {
    steps {
      echo 'step 1'
      withMaven(
        maven: 'M3',
        jdk: '1.8') {
          // Run the maven build
          sh "mvn package"
        }
    }
  }
  post {
    always {
      echo 'done'
    }
  }
}
