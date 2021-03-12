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
	"Issuing/configs"
	"Issuing/contract"
	"context"
	"crypto/ecdsa"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"math/big"
)

var(
	providerUrl string
	privateKey string

	initialSupply string
	name	string
	symbol string
	decimals uint8
	openFrozen bool
	openMint bool
	openBurn bool
)

func init(){
	configs.Load()
	rootCmd.AddCommand(deployCmd)
}

var deployCmd = &cobra.Command{
	Use:   "deploy",
	Short: "Deploy the contract to the Ethereum blockchain",
	Long:  ``,
	Run: func(cmd *cobra.Command, args []string) {

		providerUrl = viper.GetString("providerUrl")
		privateKey = viper.GetString("privateKey")

		initialSupply = viper.GetString("Token.initialSupply")
		name = viper.GetString("Token.name")
		symbol = viper.GetString("Token.symbol")
		decimals = uint8(viper.GetUint("Token.decimals"))
		openFrozen = viper.GetBool("Token.openFrozen")
		openMint = viper.GetBool("Token.openMint")
		openBurn = viper.GetBool("Token.openBurn")

	 	supply,ok := big.NewInt(0).SetString(initialSupply,10)
		if !ok {
			log.Fatal("string convert to supply failed")
			return
		}

		if decimals >= 19{
			log.Fatal("Must be less than for 19")
		}

		do(providerUrl, privateKey, supply, name, symbol, decimals, openFrozen, openMint, openBurn)
	},
}

func do(providerUrl string,privateKeyStr string,initialSupply *big.Int,name string,symbol string,decimals uint8,openFrozen bool,openMint bool,openBurn bool) {
	client, err := ethclient.Dial(providerUrl)
	if err != nil {
		log.Fatal(err)
	}

	privateKey, err := crypto.HexToECDSA(privateKeyStr)
	if err != nil {
		log.Fatal(err)
	}

	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Fatal("cannot assert type: publicKey is not of type *ecdsa.PublicKey")
	}

	fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA)
	nonce, err := client.PendingNonceAt(context.Background(), fromAddress)
	if err != nil {
		log.Fatal(err)
	}

	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		log.Fatal(err)
	}

	auth := bind.NewKeyedTransactor(privateKey)
	auth.Nonce = big.NewInt(int64(nonce))
	auth.Value = big.NewInt(0)
	auth.GasLimit = uint64(2000000)
	auth.GasPrice = gasPrice

	address, tx, _, err := contract.DeployERC20Token(auth,client,initialSupply,name,symbol,decimals,openFrozen,openMint,openBurn)
	if err != nil {
		log.Fatal(err)
	}

	log.Println(address.Hex())
	log.Println(tx.Hash().Hex())
}

