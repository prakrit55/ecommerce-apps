import { createMuiTheme } from '@material-ui/core/styles';

const theme = createMuiTheme({
  palette: {
    primary: {
      main: '#6366f1',      // Indigo
      dark: '#4f46e5',
      light: '#818cf8',
      contrastText: '#ffffff',
    },
    secondary: {
      main: '#10b981',      // Emerald / Mint Teal
      dark: '#059669',
      light: '#34d399',
      contrastText: '#ffffff',
    },
    background: {
      default: '#f8fafc',    // Slate 50
      paper: '#ffffff',
    },
    text: {
      primary: '#0f172a',    // Slate 900
      secondary: '#475569',  // Slate 600
    },
  },
  typography: {
    fontFamily: [
      'Plus Jakarta Sans',
      'Inter',
      '-apple-system',
      'BlinkMacSystemFont',
      '"Segoe UI"',
      'Roboto',
      '"Helvetica Neue"',
      'Arial',
      'sans-serif',
    ].join(','),
    h1: {
      fontWeight: 800,
    },
    h2: {
      fontWeight: 700,
    },
    h3: {
      fontWeight: 700,
    },
    h4: {
      fontWeight: 700,
    },
    h5: {
      fontWeight: 600,
    },
    h6: {
      fontWeight: 600,
    },
    button: {
      textTransform: 'none',
      fontWeight: 600,
    },
  },
  shape: {
    borderRadius: 16,
  },
  overrides: {
    MuiButton: {
      root: {
        borderRadius: 12,
        padding: '8px 20px',
        transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
        '&:hover': {
          transform: 'translateY(-1px)',
          boxShadow: '0 8px 20px -6px rgba(99, 102, 241, 0.3)',
        },
      },
      containedPrimary: {
        backgroundImage: 'linear-gradient(135deg, #6366f1 0%, #4f46e5 100%)',
        boxShadow: '0 4px 14px 0 rgba(99, 102, 241, 0.25)',
        border: 'none',
        '&:hover': {
          backgroundImage: 'linear-gradient(135deg, #4f46e5 0%, #3730a3 100%)',
          boxShadow: '0 6px 20px 0 rgba(99, 102, 241, 0.35)',
        },
      },
      outlined: {
        borderColor: '#e2e8f0',
        '&:hover': {
          borderColor: '#6366f1',
          backgroundColor: 'rgba(99, 102, 241, 0.04)',
        },
      },
    },
    MuiPaper: {
      rounded: {
        borderRadius: 16,
      },
      elevation3: {
        boxShadow: '0 10px 30px -10px rgba(99, 102, 241, 0.08), 0 1px 3px rgba(0, 0, 0, 0.03)',
      },
    },
    MuiTextField: {
      root: {
        '& .MuiOutlinedInput-root': {
          borderRadius: 12,
          '& fieldset': {
            borderColor: '#e2e8f0',
            transition: 'border-color 0.2s ease',
          },
          '&:hover fieldset': {
            borderColor: '#cbd5e1',
          },
          '&.Mui-focused fieldset': {
            borderColor: '#6366f1',
          },
        },
      },
    },
  },
});

export default theme;
