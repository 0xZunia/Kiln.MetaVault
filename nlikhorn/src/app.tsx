import { Center, Container, Text } from "@chakra-ui/react";
import { NavBar } from "@/components/custom/NavBar";
import { ColorModeButton } from "./components/ui/color-mode";

function App() {
	return (
		<Center height={"100svh"}>
			<Container
				maxWidth={"xl"}
				boxSize={"full"}
				padding={2}
				position={"relative"}
			>
				<Text>Test</Text>
				<ColorModeButton />

				<NavBar />
			</Container>
		</Center>
	);
}

export default App;
