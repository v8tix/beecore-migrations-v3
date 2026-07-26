package main

import (
	"fmt"

	"github.com/google/uuid"
)

func main() {
	// Generate a new UUID (version 4)
	newUUID := uuid.New()

	// Print the UUID
	fmt.Println("Generated UUID:", newUUID.String())
}
