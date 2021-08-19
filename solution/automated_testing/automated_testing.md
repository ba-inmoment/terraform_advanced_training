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

Create a file ending in _test.go and run tests with the go test command. E.g., go test my_test.go.

```go

```

## Task 2:  Use Terratest to Deploy infrastructure
We will use Terratest to execute terraform to deploy our infrastructure into AWS.

```hcl
```

```bash
```


## Task 3: Validate infrastructure with Terratest

Terratest allows us to validate validate that the infrastructure works correctly in that environment by making HTTP requests, API calls, SSH connections, etc.

```hcl
```



## Task 4: Undeploy
Undeploy everything at the end of the test.

```
cd test/
test_file="$(ls *test.go)"
go mod init "${test_file%.*}"
go mod tidy
go test -v $test_file
```

