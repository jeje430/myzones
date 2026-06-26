<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class ManagerInvitationMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public string $managerName,
        public string $hallName,
        public string $registrationUrl,
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'تم قبول طلب انضمام صالتك — Zones',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.manager-invitation',
            with: [
                'managerName' => $this->managerName,
                'hallName' => $this->hallName,
                'registrationUrl' => $this->registrationUrl,
            ],
            text: 'emails.manager-invitation-text',
        );
    }
}
