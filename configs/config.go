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

package configs

import (
	log "github.com/sirupsen/logrus"
	"github.com/spf13/viper"
	"os"
)

func Load(){
	workDir, _ := os.Getwd()
	viper.SetConfigName("issuing")       // name of config file (without extension)
	viper.SetConfigType("yml")               // REQUIRED if the config file does not have the extension in the name
	viper.AddConfigPath(workDir + "/configs") // optionally look for config in the working directory

	err := viper.ReadInConfig() // Find and read the config file
	if err != nil {             // Handle errors reading the config file
		if _, ok := err.(viper.ConfigFileNotFoundError); ok {
			log.Warn("Config file not found; ignore error if desired")
		} else {
			log.Warn("Config file was found but another error was produced")
		}
	}
}