resource "aws_iam_server_certificate" "alb-cert" {
    name = "bboys-alb-cert"
    certificate_body = file("certificate.pem")
    private_key = file("key.pem")
}