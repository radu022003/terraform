package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestProxmox(t *testing.T) {
	t.Parallel()

	terraform_options := &terraform.Options{
		TerraformDir: "../",
		VarFiles:     []string{"credentials.tfvars"},
	}
	terraformOptions := terraform.WithDefaultRetryableErrors(t, terraform_options)

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	vms_ip_addresses := terraform.Output(t, terraformOptions, "vm_ips")

	assert.Equal(t, "[192.168.250.221 192.168.250.222]", vms_ip_addresses, "VM IPs should be the same")

}
