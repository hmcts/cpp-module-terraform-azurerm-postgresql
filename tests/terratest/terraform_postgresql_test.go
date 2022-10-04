package test

import (
	"testing"
    "github.com/stretchr/testify/assert"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"fmt"
)

func TestTerraformPostgresql(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../examples/complete",
		VarFiles: []string{"terratest.tfvars"},
		Upgrade: true,
	}

	// Defer the destroy to cleanup all created resources
	defer terraform.Destroy(t, terraformOptions)

	// This will init and apply the resources and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Assert inputs with outputs
	outputs_server_name := terraform.Output(t, terraformOptions, "server_name")
	outputs_server_fqdn := terraform.Output(t, terraformOptions, "server_fqdn")
	outputs_administrator_login := terraform.Output(t, terraformOptions, "administrator_login")
	outputs_sku_name := terraform.Output(t, terraformOptions, "sku_name")
	outputs_storage_mb := terraform.Output(t, terraformOptions, "storage_mb")
	assert.Equal(t, "[psf-lab-ccm01-hearing]", outputs_server_name)
	assert.Equal(t, "[psf-lab-ccm01-hearing.postgres.database.azure.com]", outputs_server_fqdn)
	assert.Equal(t, "[pgsqladmin]", outputs_administrator_login)
	assert.Equal(t, "[B_Standard_B2s]", outputs_sku_name)
	assert.Equal(t, "[32768]", outputs_storage_mb)

	// Verify configurations
	configurations := terraform.OutputListOfObjects(t, terraformOptions, "configurations")
	if len(configurations[0]) == 8 {
		fmt.Println("Info: Configurations list matches")
	} else {
		t.Fatal("Error: Configurations list dont match!")
	}
}
