import { Container, HStack, Heading } from "@chakra-ui/react";
import { ColorModeButton } from "../ui/color-mode";
import { HeadingContext } from "@/routes/__root";
import { useContext } from "react";

export function Header() {
	const { heading } = useContext(HeadingContext);

	return (
		<Container
			zIndex={"sticky"}
			position={"sticky"}
			top={3}
			left={0}
			padding={0}
		>
			<HStack
				justify={"space-between"}
				paddingY={2}
				paddingX={3}
				rounded={"md"}
				shadow={"sm"}
				borderWidth={"1px"}
				borderColor={"border"}
				colorPalette={"orange"}
				bgColor={"bg"}
			>
				<Heading>{heading}</Heading>
				<ColorModeButton />
			</HStack>
		</Container>
	);
}
