output "cluster_name" {
  value = "${aws_ecs_cluster.SpotHero-ECS-Cluster.name}"
}

output "service_name" {
  value = "${aws_ecs_service.SpotHero-ECS.name}"
}

output "ECR_repo" {
  value = "${data.aws_ecr_repository.SpotHero-Repo.repository_url}"
}