package types

import (
	"bytes"
	"encoding/json"

	"sigs.k8s.io/yaml"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

const (
	CraneRunnerConfigVersion = "crane.konveyor.io/v1alpha1"
	CraneRunnerConfigKind    = "CraneRunnerConfig"
)

type CraneRunnerConfig struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	SourceContext   string `json:"sourceContext,omitempty" yaml:"sourceContext,omitempty"`
	SourceNamespace string `json:"sourceNamespace,omitempty" yaml:"sourceNamespace,omitempty"`

	DestinationContext   string `json:"destinationContext,omitempty" yaml:"destinationContext,omitempty"`
	DestinationNamespace string `json:"destinationNamespace,omitempty" yaml:"destinationNamespace,omitempty"`
}

// Unmarshal replace k with the content in YAML input y
func (c *CraneRunnerConfig) Unmarshal(y []byte) error {
	j, err := yaml.YAMLToJSON(y)
	if err != nil {
		return err
	}
	dec := json.NewDecoder(bytes.NewReader(j))
	dec.DisallowUnknownFields()
	var cr CraneRunnerConfig
	err = dec.Decode(&cr)
	if err != nil {
		return err
	}
	*c = cr
	return nil
}
