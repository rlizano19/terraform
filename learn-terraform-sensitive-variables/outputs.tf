# Output declarations
output "load_balancer_default_ip" {
  description = "The external ip address of the forwarding rule for default lb."
  value       = module.gce-lb-fr.external_ip
}