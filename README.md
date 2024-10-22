

# tf-exercise

Task: We used Terraform to provision, manage, and launch an Auto Scaling group with traffic managed by a load balancer and we defined a scaling policy to automatically ensure at least two or more EC2 instances are running in the ASG. 



Providers.tf ---> assigned aws as the provider and created a region variable.
<br>

To deploy: 
'''
terraform init
terraform validate
terraform plan
terraform apply
'''

Steps Taken:
1. We used the vpc module to create a new VPC with public subnets in available AZs that we provisioned our resources in. 
2. Then we defined the AMI for instance
3. We configure a launch template to specify the EC2 instance configuration that an ASG will use to launch each new instance.
4. We then configured our ASG.
5. We create an ALB that will be attached to the ASG
6. We configured a LB listener to specify how to handle any HTTP requests to port 80 (aka forward all requests to the load balancer to a target group).
6. Created target group configuration which defined the collection of instances our ALB will send traffic to.
7. Created Security Groups for ASG EC2 instances and Load Balancer

