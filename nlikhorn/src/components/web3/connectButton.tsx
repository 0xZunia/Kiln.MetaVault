import { Button } from "@chakra-ui/react";
import { useConnect } from "wagmi";

export function ConnectButton() {
	const { connectors, connect } = useConnect();

	return connectors.map((connector) => (
		<Button
			key={connector.uid}
			onClick={() => connect({ connector })}
			justifySelf={"center"}
			alignSelf={"center"}
		>
			{connector.name}
		</Button>
	));
}
