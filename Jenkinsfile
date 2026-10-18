pipeline {
  agent any

  // A real team would use a webhook. Jenkins here is not reachable from the
  // internet, so it checks GitHub for new commits every 2 minutes instead.
  triggers { pollSCM('H/2 * * * *') }

  parameters {
    booleanParam(name: 'DESTROY', defaultValue: false,
                 description: 'Tick this to delete everything in AWS')
  }

  environment {
    DH                    = credentials('dockerhub')              // DH_USR and DH_PSW
    AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
    AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
  }

  stages {
    stage('Build image') {
      when { expression { !params.DESTROY } }
      steps {
        sh 'docker build --build-arg BUILD=$BUILD_NUMBER -t $DH_USR/lab-web:$BUILD_NUMBER app'
      }
    }

    stage('Push image') {
      when { expression { !params.DESTROY } }
      steps {
        sh '''
          echo "$DH_PSW" | docker login -u "$DH_USR" --password-stdin
          docker push $DH_USR/lab-web:$BUILD_NUMBER
        '''
      }
    }

    stage('Terraform') {
      steps {
        dir('terraform') {
          sh '''
            mkdir -p /var/jenkins_home/tfstate
            terraform init -input=false
            MYIP="$(curl -s https://checkip.amazonaws.com)/32"
            if [ "$DESTROY" = "true" ]; then
              terraform destroy -auto-approve -input=false -var "my_ip_cidr=$MYIP"
            else
              terraform apply -auto-approve -input=false -var "my_ip_cidr=$MYIP"
            fi
          '''
        }
      }
    }

    stage('Ansible: k3s and deploy') {
      when { expression { !params.DESTROY } }
      steps {
        withCredentials([sshUserPrivateKey(credentialsId: 'ec2-key', keyFileVariable: 'KEY')]) {
          sh '''
            IP="$(cd terraform && terraform output -raw public_ip)"
            export ANSIBLE_HOST_KEY_CHECKING=False
            ansible-playbook -i "$IP," -u ubuntu --private-key "$KEY" ansible/site.yml \
              -e "image_name=$DH_USR/lab-web:$BUILD_NUMBER"
          '''
        }
      }
    }

    stage('Smoke test') {
      when { expression { !params.DESTROY } }
      steps {
        sh '''
          IP="$(cd terraform && terraform output -raw public_ip)"
          for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
            if curl -fs "http://$IP:30080" | grep -q "Build $BUILD_NUMBER<"; then
              echo "Smoke test passed: http://$IP:30080"
              exit 0
            fi
            sleep 5
          done
          echo "Smoke test failed"
          exit 1
        '''
      }
    }
  }
}
