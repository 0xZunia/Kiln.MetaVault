import {
	Link as ChakraLink,
	Container,
	HStack,
	IconButton,
} from "@chakra-ui/react";
import { Link } from "@tanstack/react-router";
import { LuHouse, LuPiggyBank, LuVault } from "react-icons/lu";

export function NavBar() {
	return (
		<Container position={"absolute"} bottom={3} left={0}>
			<HStack
				justify={"space-around"}
				paddingY={2}
				paddingX={3}
				rounded={"md"}
				shadow={"sm"}
				borderWidth={"1px"}
				borderColor={"border"}
				colorPalette={"orange"}
				bgColor={"bg"}
			>
				<ChakraLink asChild>
					<Link to="/">
						<IconButton>
							<LuHouse />
						</IconButton>
					</Link>
				</ChakraLink>

				<ChakraLink asChild>
					<Link to="/">
						<IconButton>
							<LuVault />
						</IconButton>
					</Link>
				</ChakraLink>

				<ChakraLink asChild>
					<Link to="/earn">
						<IconButton>
							<LuPiggyBank />
						</IconButton>
					</Link>
				</ChakraLink>
			</HStack>
		</Container>
	);
}
