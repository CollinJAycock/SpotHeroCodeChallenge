provider "aws" {
  profile    = "default"
  region     = "us-east-1"
}

module "Networking"  {
  source                      = "./modules/networking"
}

module "ECS" {

    source                     = "./modules/ECS"
    vpc_id                     = module.Networking.vpc_id
    subnet_ids                 = module.Networking.Spothero-public_subnets_id
}

module "CodePipline" {

    source                     = "./modules/codePipeline"
    repository_url             = module.ECS.ECR_repo
    region                     = "us-east-1"
    ecs_cluster_name           = module.ECS.cluster_name
    ecs_service_name           = module.ECS.service_name
    GitHub_OAuth_Token         = "PUT YOUR GIT HUB TOKEN"
    run_task_subnet_id         = module.Networking.Spothero-public_subnets_id
    run_task_security_group_ids= [module.Networking.Spothero-Default-SecurityGroup_id]   
}