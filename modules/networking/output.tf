output "vpc_id" {
  value = aws_vpc.SpotHero-VPC.id
}

output "Spothero-public_subnets_id" {
  value = [aws_subnet.SpotHero-subnet-Public1.id,aws_subnet.SpotHero-subnet-Public2.id]
}

//output "Spothero-private_subnets_id" {
//  value = [aws_subnet.SpotHero-subnet-Private1.id,aws_subnet.SpotHero-subnet-Private2.id]
//}

output "Spothero-Default-SecurityGroup_id" {
  value = aws_security_group.Spothero-Default-SecurityGroup.id
}

