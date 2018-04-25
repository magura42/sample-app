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
    /*
    stage('packer') {
      environment {
        PACKER_HOME = tool name: 'packer-1.1.3', type: 'biz.neustar.jenkins.plugins.packer.PackerInstallation'
        PACKER_SUBSCRIPTION_ID="fcc1ad01-b8a5-471c-812d-4a42ff3d6074"
        PACKER_CLIENT_ID="7d68a4b4-e3f1-4bf7-80ee-50a821728ce5"
        PACKER_CLIENT_SECRET=credentials('055c1ba4-c706-451c-aa45-0cd72ec796e8')
        PACKER_LOCATION="westeurope"
        PACKER_TENANT_ID="787717a7-1bf4-4466-8e52-8ef7780c6c42"
        PACKER_OBJECT_ID="56e89fa0-e748-49f4-9ff0-0d8b9e3d4057"
        PACKER_IMAGE_NAME = "mh-${env.BUILD_ID}"

      }
      steps {
        wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
          echo 'validate packer json..'
          sh "${PACKER_HOME}/packer validate packer/azure-template.json"
          echo 'build packer...'
          sh "${PACKER_HOME}/packer build packer/azure-template.json"
        }
      }
    }*/
    stage('terraform') {
      environment {
        TERRAFORM_HOME = tool name: 'terraform-0.11.3'
        ARM_SUBSCRIPTION_ID="fcc1ad01-b8a5-471c-812d-4a42ff3d6074"
        ARM_CLIENT_ID="7d68a4b4-e3f1-4bf7-80ee-50a821728ce5"
        ARM_CLIENT_SECRET=credentials('055c1ba4-c706-451c-aa45-0cd72ec796e8')
        ARM_TENANT_ID="787717a7-1bf4-4466-8e52-8ef7780c6c42"
        ARM_ENVIRONMENT="public"
        TF_VAR_build_id="${env.BUILD_ID}"
        TF_VAR_user="mh"
        TF_VAR_password=credentials('055c1ba4-c706-451c-aa45-0cd72ec796e8')
      }
      steps {
        wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'xterm']) {
          dir ('terraform') {
            script {
              echo 'terraform init...'
              sh "${TERRAFORM_HOME}/terraform init -input=false -backend-config=\"key=${TF_VAR_user}.terraform.tfstate\""

              echo 'terraform plan ..'
              sh "${TERRAFORM_HOME}/terraform plan -out tfplan"

              echo 'terraform apply...'
              sh "${TERRAFORM_HOME}/terraform apply -input=false -auto-approve tfplan"
            }
          }
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
