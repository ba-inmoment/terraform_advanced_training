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
Install Go on your training workstation

```bash
 wget -c https://dl.google.com/go/go1.14.2.linux-amd64.tar.gz -O - | sudo tar -xz -C /usr/local
export PATH=$PATH:/usr/local/go/bin
```

```bash
go version
```

Create a new folder within your `terraform-aws-server` repository called `test`

Create a file call `server_test.go` and run tests with the go test command.

`hello_test.go`

```go
package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformHelloWorldExample(t *testing.T) {
	
	ami := "ami-019212a8baeffb0fa"
	securityGroups := "[\"sg-076f99e91f81f59bb\"]"
	subnetID := "subnet-097cef8da2055de87"
	identity := "terraform-training-cricket"
	keyName := "terraform-training-cricket-key"
	privateKey := "-----BEGIN RSA PRIVATE KEY-----MIIEpgIBAAKCAQEA3ZMrka/dsqSIkvAlJvHo7Kb87HjpZCs8qOSL6SfuonxVk7qxgSh1wd/20paTDo2CErhrVlsyXpKeuDFP5K9O1FRh7O8YwI8gmMKNglZFHYayNk90gwPSjb6gRvSYJVpgreNdJGXcOK/TNnBibUZqKPZy4FPOwUkkcCmPphR/PQAk2HrI+mPLpT8FHFkhyQObpo2mgHHr4VxNmilUUzrIaFxlH4pLJdPsQC6TOTumzdNSljoxXO9B5MmlwiSHSYg8bBI7pbW+L/6camJHiIBxV3rb6OMG88rcDV+Sk4BQJiZNh0N0qK2Wf6e8xyrmvovNWpkV3Xoe8dbMIeMtxMT3KwIDAQABAoIBAQDWRakflRPu2wAcING8zLn0iTQUNoV1Uf6yUXofuncieNyFJUjc31SpbT2SvvxtWVlNYzyh4UVfgait9ToOq52u5f9hEoM8S+047QPN5EGoYQbcUJAa1sp6OrtigszTaogOAM6lEUAbLaUygxIcHLky7cl/uGw8LNBpCzgYYr/9KuZ4YHDAEzuYvJedxc+BWIku5B1lfQrV9/tiKDx77jgt0yE3ZbXh7EV9Z7bL5k2nJ1B/RptFObFqvG0B/WslcyjZetbwJqU+2yIi05TJZeLzWp7FNxBhaaSnh7l9WiTY3kpVKC4jsSFzzaGTGe7lGluDM9GgbI9iy2FL3N9pzteRAoGBAPeu437cTarG1tc4ERWJwVlOopW4pdhAPwLZrNhmPMzG331tU3EYRM2Je8s8UdQI6yzHuFMgNPYYYFN9YqXeknALuYz1SRA/ypc7od7HJW3sgcuuX5i0tTCXx0M+ko8+zue0lsRGTHAW9qBk2++bZHImMjO74Gu13q4s/9Eeh3uTAoGBAOUD2hp4vrkN6JmWK99ZdCJxdSgY1ha+Xi+xImR9KzTrmaDlmD8ppNJSxuFKs8NK7XTuNy3K1MZ4jT1ywFldr4qOnTIVkRaZXk/cmubRitqI8T4l8iNPojaukWsx1irJTOglUSYTDuq+kk0sCLrNRdF+cgEXdwkTkqpC60YZYUUJAoGBAKBWFa0U/i40Y/WUtPKFZ6XhkrxreOjBxkiZExxPKsLBZwHyGNcYh8mqW3oYRTyGvX8Slw8wxTgeVZUWkRqhN5jS7j4Ct1aOhR5bmxD1SBSdyvRIoFfhe33Gc1bjlcqnNRenvwW2IFtbcjIouHum02JVuZ/l2oS/ijSkqsH8CmaDAoGBALo1SpZxjOnclD6lKuD80//Zbp/+qbxuZxiyFzvLxmDOG+kGJaddzeUxZwHyAn4NI0wLERSLsjv58yV+c0V2dm/bi5cYkBLm+xdGUTDSOet8o2Kb6eiqLEP35sdZC0FY0c6D4RprLprR/xT+c86nb1hqTnnywVfA8WS86p3hrwQ5AoGBAN4GognBFPZDo6xZcv3PoEsRQ4Q9RmaHAT3/zMwFIurnBqg+jWeNiyBTQ+0/S0e6v2tzR8iVCbrHbq9juGi3j2FGOQawop0vyJPc+1lOnjjXrJp6OQPwgxNkAePZapwfzw/zvm7ersnQBOhJ4+frx9EXHyRArT/O0+V7hlwVHV7l-----END RSA PRIVATE KEY-----"

	// retryable errors in terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		
		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"ami": ami,
			"subnet_id": subnetID,
			"vpc_security_group_ids":  securityGroups,
			"identity": identity,
			"key_name": keyName,
			"private_key": privateKey, 
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	output := terraform.Output(t, terraformOptions, "hello_world")
	assert.Equal(t, "Hello, World!", output)
}
```

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