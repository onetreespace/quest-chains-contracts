/* eslint-disable import/no-unresolved */
import 'focus-visible/dist/focus-visible';
import '@/assets/bg.scss';

import { ChakraProvider } from '@chakra-ui/react';
import { Global } from '@emotion/react';
import { AppProps } from 'next/app';
import { withUrqlClient } from 'next-urql';

import { AppLayout } from '@/components/AppLayout';
import { GRAPH_URL } from '@/utils/constants';
import { globalStyles, theme } from '@/utils/theme';
import { WalletProvider } from '@/web3';

const App = ({ Component, pageProps }: AppProps): JSX.Element => {
  return (
    <ChakraProvider resetCSS theme={theme}>
      {/* <div className="background">
        <span></span>
        <span></span>
        <span></span>
        <span></span>
        <span></span>
        <span></span>
        <span></span>
      </div> */}
      <Global styles={globalStyles} />
      <WalletProvider>
        <AppLayout>
          <Component {...pageProps} />
        </AppLayout>
      </WalletProvider>
    </ChakraProvider>
  );
};

export default withUrqlClient(() => ({ url: GRAPH_URL }), {
  ssr: true,
  staleWhileRevalidate: true,
})(App);
