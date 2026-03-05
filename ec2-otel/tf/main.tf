resource "aws_key_pair" "ec2_otel" {
  key_name   = "${var.aws_ssh_key_name}${var.name_suffix}"
  public_key = file(var.public_ssh_key_path)
}

resource "aws_cloudformation_stack" "ec2_otel" {
  name = var.thing_name

  template_body = file("${path.module}/../otel-vm.yaml")

  parameters = {
    KeyName = aws_key_pair.ec2_otel.key_name
  }

  depends_on = [aws_key_pair.ec2_otel]
}
