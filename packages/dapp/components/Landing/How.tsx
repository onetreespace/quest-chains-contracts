import {
  Box,
  Flex,
  Heading,
  HStack,
  Image,
  Link,
  Text,
  useBreakpointValue,
} from '@chakra-ui/react';
import { useRef } from 'react';

export const How: React.FC = () => {
  const ref = useRef<HTMLDivElement>(null);
  const isSmallScreen = useBreakpointValue({ base: true, lg: false });

  return (
    <HStack
      w="full"
      align="center"
      justify="center"
      minH={{ base: '70vh', md: '100vh' }}
      bg="dark"
      bgPosition="center"
      bgAttachment="fixed"
      bgSize="cover"
      position="relative"
      id="how"
    >
      <Box
        position="absolute"
        borderRadius="full"
        right="-300px"
        top="-300px"
        height="600px"
        filter="blur(484px)"
        width="600px"
        background="#2DF8C7"
        zIndex={-3}
      />
      <Flex
        ref={ref}
        display="flex"
        flexDirection="column"
        justifyContent="center"
        lineHeight={{ base: 'lg', '2xl': '2xl' }}
        pl={0}
        marginInlineStart="0 !important"
        zIndex={100}
        fontWeight="normal"
        color="white"
      >
        <Flex
          align="center"
          mb={{ base: 0, md: 8 }}
          flexDirection={{ base: 'column', md: 'row' }}
        >
          {!isSmallScreen && (
            <Image src="Landing/Circles3.svg" alt="circles3" mr={10} />
          )}
          <Heading
            color="main"
            fontSize={{ base: 36, md: 79 }}
            pb={10}
            fontWeight="normal"
            display="flex"
            flexDir="column"
            textAlign={{ base: 'center', md: 'initial' }}
          >
            How <Text color="white">does it work?</Text>
          </Heading>
        </Flex>
        <Flex align="center" mb={10}>
          <Flex
            flexDir="column"
            fontSize={{ base: 'md', md: '3xl' }}
            ml={{ base: 0, md: 20 }}
            px={{ base: 12, md: 0 }}
          >
            <Text>
              Learning & engaging becomes rewarding, as questers receive rewards
              for completed quests. It becomes accumulative. Build your digital
              identity and become proud of the things you accomplish or create
              quest chains and spread the knowledge.
            </Text>
            <Text>
              Show the world the
              <Link
                w="100%"
                href="https://vitalik.ca/general/2022/01/26/soulbound.html"
                _hover={{
                  textDecor: 'none',
                  bg: 'whiteAlpha.200',
                }}
                isExternal
                borderRadius="full"
                px={2}
              >
                <span style={{ color: '#2DF8C7', marginLeft: 4 }}>
                  soulbound NFTs
                </span>
              </Link>
              you have collected!
            </Text>
          </Flex>
          {!isSmallScreen && (
            <Image src="Landing/Circles4.svg" alt="circles3" mr={10} />
          )}
        </Flex>
      </Flex>
    </HStack>
  );
};
