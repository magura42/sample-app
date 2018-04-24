pipeline {
  agent any
  stages {
    /* Stage buld */
    stage('build') {
      steps {
        echo 'step to build artifact...'
        withMaven(jdk: '1.8', maven: '3.5.2') {
            // Run the maven build
            sh "mvn package"
        }
      }
    }
    stage('packer') {
      environment {
        PACKER_HOME = tool name: 'packer-1.1.3', type: 'biz.neustar.jenkins.plugins.packer.PackerInstallation'
        PACKER_SUBSCRIPTION_ID="fcc1ad01-b8a5-471c-812d-4a42ff3d6074"
        PACKER_CLIENT_ID="262d2df5-a043-458a-9d0d-27a734962cd9"
        PACKER_CLIENT_SECRET=credentials('b5d19ab8-1943-4824-b5c2-851ee91e71ab')
        PACKER_LOCATION="westeurope"
        PACKER_TENANT_ID="787717a7-1bf4-4466-8e52-8ef7780c6c42"
        PACKER_OBJECT_ID="56e89fa0-e748-49f4-9ff0-0d8b9e3d4057"
      }
      steps {
        wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
          echo 'validate packer json..'
          sh "${PACKER_HOME}/packer validate packer/azure-template.json"
          echo 'build packer...'
          sh "${PACKER_HOME}/packer build packer/azure-template.json"
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
