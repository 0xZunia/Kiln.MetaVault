import { Button, Card, Container, Text } from "@chakra-ui/react";
import { useConnect } from "wagmi";

export function ConnectButton() {
	const { connectors, connect } = useConnect();

	return (
		<Container>
			<Card.Root>
				<Card.Body>
					<Card.Title>Connection</Card.Title>
					{connectors.length === 0 ? (
						<Text>
							You have no connectors installed, try again after setting one up
						</Text>
					) : (
						<Text>Use whatever connecter you prefer</Text>
					)}
				</Card.Body>
				<Card.Footer>
					{connectors.map((connector) => (
						<Button
							key={connector.uid}
							onClick={() => connect({ connector })}
							justifySelf={"center"}
							alignSelf={"center"}
							colorPalette={"green"}
						>
							{connector.name}
						</Button>
					))}
				</Card.Footer>
			</Card.Root>
		</Container>
	);
}
