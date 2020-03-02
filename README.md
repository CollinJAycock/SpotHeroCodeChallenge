# SpotHeroCodeChallenge
 
# Steps to create stack:

1. Install AWSCLI on your local machine see:https://aws.amazon.com/cli/
2. Install Terraform on your local machine see:https://learn.hashicorp.com/terraform/getting-started/install.html
3. Get credintals from AWS and store on your local machine  see:https://www.terraform.io/docs/providers/aws/index.html
4. Clone this repo
5. Open a terminal and navigate to the folder containg "SpotHeroCodeChalenge.tf"
6. Execute "terraform init" to initalize providers and modules
7. Execute "terraform apply" and validate the execution plan 
Note: If you get "Error: failed to render : <template_file>:10,26-40: Unknown variable; There is no variable named "repository_url". just run "terraform apply" again
8. Say yes to the prompt
9. Get a cup of coffee your have 5 - 10 min <-- important step!
10. The environment should now be alive. Log into your console to investigate


# Steps to clean up
1. Execute "terraform apply" and validate the execution plan 
2. Say yes to the prompt
