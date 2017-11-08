[
  {
    "name": "jenkins",
    "image": "jenkins/jenkins:lts",
    "cpu": 128,
    "memory": 1024,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 8080,
        "hostPort": 80
      },
      {
        "containerPort": 50000,
        "hostPort": 50000
      }
    ],
    "mountPoints": [
      {
        "sourceVolume": "jenkins-home",
        "containerPath": "/var/jenkins_home"
      }
    ]
  }
]
