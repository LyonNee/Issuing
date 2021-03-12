/*
 *  Copyright [2021] [lyon.nee@outlook.com]
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

package cmd

import (
	"bytes"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"testing"
)

func executeCommand(root *cobra.Command, args ...string) (output string, err error) {
	_, output, err = executeCommandC(root, args...)
	return output, err
}

func executeCommandC(root *cobra.Command, args ...string) (c *cobra.Command, output string, err error) {
	buf := new(bytes.Buffer)
	root.SetOut(buf)
	root.SetErr(buf)
	root.SetArgs(args)

	c, err = root.ExecuteC()

	return c, buf.String(), err
}

func TestDeployWithConfig(t *testing.T) {
	loadConf()

	cmd := rootCmd

	output,err := executeCommand(cmd,"deploy")
	if output != "" {
		t.Errorf("Unexpected output: %v", err)
	}
	if err != nil {
		t.Errorf("Unexpected error: %v", err)
	}
}

func loadConf(){
	viper.SetConfigName("issuing_test")       // name of config file (without extension)
	viper.SetConfigType("yml")               // REQUIRED if the config file does not have the extension in the name
	viper.AddConfigPath("/mnt/private_projects/Issuing/configs") // optionally look for config in the working directory

	err := viper.ReadInConfig() // Find and read the config file
	if err != nil {             // Handle errors reading the config file
		if _, ok := err.(viper.ConfigFileNotFoundError); ok {
			// Config file not found; ignore error if desired
		} else {
			// Config file was found but another error was produced
		}
	}
}