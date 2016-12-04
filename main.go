package main

import (
	"flag"
	"fmt"
)

func main() {
	cmd := flag.String("cmd", "", "Btrfs command")
	dst := flag.String("dst", "", "Btrfs destination path")

	flag.Parse()

	switch *cmd {
	case "create":
	default:
		fmt.Println("Invalid command")
		flag.Usage()
		return
	}

	if *dst == "" {
		fmt.Println("Empty destination path")
		flag.Usage()
		return
	}
}
