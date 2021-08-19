# Lab: Automated Testing

Duration: 15 minutes

We may want to validate and possibly suppress and sensitive information defined within our variables.

- Task 1: Write a unit test for your code
- Task 2: Use Terratest to Deploy infrastructure
- Task 3: Validate infrastructure with Terratest
- Task 4: Undeploy

The only real way to test infrastructure code beyond static analysis is by deploying it to a real environment, whatever environment you happen to be using.

[Terratest](https://terratest.gruntwork.io) is a Go library that provides patterns and helper functions for testing infrastructure, with 1st-class support for Terraform, Packer, Docker, Kubernetes, AWS, GCP, and more.

## Task 1: Write a unit test for your code

Create a new folder within your `terraform-aws-server` repository called `test`

Create a file ending in server_test.go and run tests with the go test command. E.g., go test server_test.go.

`server_test.go`

```go
package test

import (
	//"reflect"
	"fmt"
	"strings"
	"testing"
	"time"
	//"io"
	//"io/ioutil"
	"net/http"

	"github.com/gruntwork-io/terratest/modules/shell"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/gruntwork-io/terratest/modules/ssh"
)

func TestEnvironment(t *testing.T) {
	t.Parallel()

	// Configuring the Terraform Options that we use to pass into terraform. We have an environment variables map to declare env variables. We also
	// configure the options with default retryable errors to handle the most common retryable errors encountered in
	// terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../",
	})

	// defer is like a try finally, where at the end of this test, this line will always run. This line calls a Terraform destroy, which always gets called.
	defer terraform.Destroy(t, terraformOptions)

	// Run `terraform init` and `terraform apply`. The test fails if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	server_dns := terraform.Output(t, terraformOptions, "public_dns")
	server_ip := terraform.Output(t, terraformOptions, "public_ip")
	
	//pings the workstations, will fail if they do not ping. The ping will wait for 60 seconds to ensure the ip is ready and can be pinged.
	
	cmd := shell.Command{
		Command: "ping",
		Args:    []string{"-w", "180", "-c", "10", server_ip},
	}
	shell.RunCommandAndGetOutput(t, cmd)

	//ensure that you can http get the workstations and the response is 200
	resp, err := http.Get("http://" + server_dns)
	assert.Nil(t, err)
	defer resp.Body.Close()
	assert.Equal(t, 200, resp.StatusCode)
}
```

## Task 2:  Use Terratest to Deploy infrastructure
We will use Terratest to execute terraform to deploy our infrastructure into AWS.

```bash
cd test/
test_file="$(ls *test.go)"
go mod init "${test_file%.*}"
go mod tidy
go test -v $test_file
```

## Task 3: Validate infrastructure with Terratest

Terratest allows us to validate validate that the infrastructure works correctly in that environment by making HTTP requests, API calls, SSH connections, etc.

```hcl
```



## Task 4: Undeploy
The final step of our test is to undeploy everything at the end of the test.Terratest allows us to perform a terraform destroy at the end of the testing cycle.